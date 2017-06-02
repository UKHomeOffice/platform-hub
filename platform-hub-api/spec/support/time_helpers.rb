module TimeHelpers

  RSpec.shared_context 'time helpers' do

    def move_time_to datetime
      Timecop.freeze datetime
    end

    let(:now) { DateTime.now.utc }
    let(:now_json_value) { now.utc.iso8601 }

    before do
      move_time_to now
    end

    after do
      Timecop.return
    end

  end

end
