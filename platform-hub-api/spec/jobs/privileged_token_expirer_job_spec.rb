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
    before do
      FeatureFlagService.create_or_update(:kubernetes_tokens, true)
    end

    context 'for non privileged kubernetes token' do
      before do
        @token = create :user_kubernetes_token
      end

      it 'skips that token' do
        expect(@token).to receive(:deescalate).never
        expect(AuditService).to receive(:log).never

        PrivilegedTokenExpirerJob.new.perform
      end
    end

    context 'for privileged kubernetes token' do
      let!(:not_privileged_group) { create :kubernetes_group }
      let!(:privileged_group) { create :privileged_kubernetes_group }
      let(:groups) { [ privileged_group.name, not_privileged_group.name ] }

      context 'when privileged group expiration time lapsed' do
        before do
          @token = create :privileged_kubernetes_token, groups: groups, expire_privileged_at: 1.minute.ago
        end

        it 'deescalates given kubernetes token and registers an audit' do
          expect(AuditService).to receive(:log).with(
            action: 'deescalate',
            auditable: @token
          )

          PrivilegedTokenExpirerJob.new.perform

          @token.reload
          expect(@token.groups).to match_array([ not_privileged_group.name ])
          expect(@token.expire_privileged_at).to be nil
        end
      end

      context 'when privileged group expiration time has not been reached yet' do
        before do
          @token = create :privileged_kubernetes_token, groups: groups, expire_privileged_at: 1.minute.from_now
        end

        it 'skips that token' do
          expect(@token).to receive(:deescalate).never
          expect(AuditService).to receive(:log).never

          PrivilegedTokenExpirerJob.new.perform
        end
      end
    end
  end

end
