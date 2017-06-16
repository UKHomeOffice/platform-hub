module TimeHelpers

  RSpec.shared_context 'time helpers' do

    def move_time_to datetime
      Timecop.freeze datetime
    end

    def now
      DateTime.now.utc
    end

    def now_json_value
      now.utc.iso8601
    end

    before do
      move_time_to now
    end

    after do
      Timecop.return
    end

  end

end
