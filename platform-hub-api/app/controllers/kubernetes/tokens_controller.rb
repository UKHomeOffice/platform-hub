class Kubernetes::TokensController < ApiJsonController

  before_action :find_identity

  # GET /:user_id
  def index
    authorize! :read, :identity
    render json: Kubernetes::TokenService.tokens_from_identity_data(identity_data)
  end

  # PATCH/PUT /:user_id/:cluster
  def create_or_update
    authorize! :manage, :identity
    tokens, created_or_updated_token = Kubernetes::TokenService.create_or_update_token(
      identity_data,
      @identity.id,
      params[:cluster],
      params[:token][:groups]
    )

    unless created_or_updated_token.valid?
      render_model_errors created_or_updated_token.errors and return
    end

    @identity.with_lock do
      @identity.data[:tokens] = tokens

      if @identity.save!
        AuditService.log(
          context: audit_context,
          action: 'update_kubernetes_identity',
          auditable: @identity,
          data: { cluster: params[:cluster] },
          comment: "Kubernetes `#{params[:cluster]}` token created or updated for user '#{@identity.user.email}' - Assigned groups: #{created_or_updated_token.groups}"
        )

        render json: created_or_updated_token
      else 
        render_model_errors @identity.errors
      end
    end
  end

  # DELETE /:user_id/:cluster
  def destroy
    authorize! :manage, :identity
    tokens, _ = Kubernetes::TokenService.delete_token(identity_data, params[:cluster])

    @identity.with_lock do
      @identity.data[:tokens] = tokens

      if @identity.save!
        AuditService.log(
          context: audit_context,
          action: 'update_kubernetes_identity',
          auditable: @identity,
          data: { cluster: params[:cluster] },
          comment: "Kubernetes `#{params[:cluster]}` token removed for user '#{@identity.user.email}'"
        )

        head :no_content
      else 
        render_model_errors @identity.errors
      end
    end
  end

  private

  def find_identity
    user = User.find(params[:user_id])
    @identity = user.identity(:kubernetes)

    if @identity.nil?
      @identity = user.identities.create!(
        provider: :kubernetes,
        external_id: user.email,
        data: {tokens: []}
      )
    end
  end

  def identity_data
    @identity.try(:data) || {}
  end
end
