require 'rails_helper'

RSpec.describe PrivilegedTokenExpirerJob, type: :job do

  describe '.is_already_queued' do
    it 'should recognise when the job is already queued' do
      expect(PrivilegedTokenExpirerJob.is_already_queued).to be false

      PrivilegedTokenExpirerJob.perform_later

      expect(PrivilegedTokenExpirerJob.is_already_queued).to be true
    end
  end

  describe '.perform' do
    let!(:kubernetes_groups) { create :kubernetes_groups_hash_record }

    let(:cluster_name) { 'development' }

    before do
      FeatureFlagService.create_or_update(:kubernetes_tokens, true)

      user = create(:user)

      @kubernetes_identity = create(:kubernetes_identity, user: user, data: { tokens: [] })
      user_kube_token = {
        identity_id: @kubernetes_identity.id,
        cluster: cluster_name,
        token: ENCRYPTOR.encrypt('some-random-token'),
        uid: 'some-random-uid',
        groups: groups,
        expire_privileged_at: expire_privileged_at
      }
      @kubernetes_identity.data["tokens"] << user_kube_token
      @kubernetes_identity.save!
    end

    context 'for kubernetes identity token with non privileged group' do
      let(:groups) { [ 'not-privileged-group'] }
      let(:expire_privileged_at) { nil }

      it 'does not update kubernetes identity' do
        expect(@kubernetes_identity).to receive(:save!).never
        expect(AuditService).to receive(:log).never

        PrivilegedTokenExpirerJob.new.perform
      end
    end

    context 'for kubernetes identity token with privileged group' do
      let(:groups) { Kubernetes::TokenGroupService.privileged_group_ids }

      context 'when privileged group expiration time lapsed' do
        let(:expire_privileged_at) { 1.minute.ago }

        it 'updates user kubernetes identity and registers an audit' do
          expect(AuditService).to receive(:log).with(
            action: 'deescalate_kubernetes_token',
            auditable: @kubernetes_identity,
            data: { cluster: cluster_name },
            comment: "Privileged kubernetes token expired for `#{@kubernetes_identity.user.email}` in `#{cluster_name}` via background job."
          )

          PrivilegedTokenExpirerJob.new.perform

          kube_token = @kubernetes_identity.reload.data["tokens"].first
          expect(kube_token['groups']).to be_empty
          expect(kube_token['expire_privileged_at']).to be_nil
        end
      end

      context 'when privileged group expiration time has not been reached yet' do
        let(:expire_privileged_at) { 1.minute.from_now }

        it 'does not update user kubernetes identity' do
          expect(@kubernetes_identity).to receive(:save!).never
          expect(AuditService).to receive(:log).never

          PrivilegedTokenExpirerJob.new.perform
        end
      end
    end
  end

end
