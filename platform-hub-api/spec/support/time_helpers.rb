module TimeHelpers

  RSpec.shared_context 'time helpers' do

    let(:now) { Time.now }
    let(:now_json_value) { now.utc.iso8601 }

    before do
      Timecop.freeze(now)
    end

    after do
      Timecop.return
    end

  end

end
