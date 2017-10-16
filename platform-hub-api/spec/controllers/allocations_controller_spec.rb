require 'rails_helper'

RSpec.describe AllocationsController, type: :controller do

  describe 'DELETE #destroy' do
    before do
      @allocation = create :allocation,
        allocatable: create(:kubernetes_group),
        allocation_receivable: create(:project)
    end

    it_behaves_like 'unauthenticated not allowed'  do
      before do
        delete :destroy, params: { id: @allocation.id }
      end
    end

    it_behaves_like 'authenticated' do

      it_behaves_like 'not an admin so forbidden'  do
        before do
          delete :destroy, params: { id: @allocation.id }
        end
      end

      it_behaves_like 'an admin' do

        it 'should delete the specified allocation' do
          expect(Allocation.exists?(@allocation.id)).to be true
          expect(Audit.count).to eq 0
          delete :destroy, params: { id: @allocation.id }
          expect(response).to be_success
          expect(Allocation.exists?(@allocation.id)).to be false
          expect(Audit.count).to eq 1
          audit = Audit.first
          expect(audit.action).to eq 'destroy'
          expect(audit.auditable_type).to eq Allocation.name
          expect(audit.auditable_id).to eq @allocation.id
          expect(audit.user.id).to eq current_user_id
        end

      end

    end
  end

end
