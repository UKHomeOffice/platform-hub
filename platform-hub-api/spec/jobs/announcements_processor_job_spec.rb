require 'rails_helper'

RSpec.describe AnnouncementsProcessorJob, type: :job do

  describe '.is_already_queued?' do
    it 'should recognise when the job is already queued' do
      expect(AnnouncementsProcessorJob.is_already_queued?).to be false

      AnnouncementsProcessorJob.perform_later

      expect(AnnouncementsProcessorJob.is_already_queued?).to be true
    end
  end

end
