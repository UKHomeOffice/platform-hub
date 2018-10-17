require 'rails_helper'

RSpec.describe HelpSearchStatsService, type: :service do

  let(:key) { HelpSearchStatsService::KEY }

  describe 'counting queries, getting query stats and marking as hidden' do
    it 'should keep a record of query counts as well as last n result sizes per queries' do
      expect(subject.query_stats).to be_empty

      subject.count_query 'foo', 21

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 1, last_result_sizes: [21], hidden: false }
      ])

      subject.count_query 'Foo ', 23

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 2, last_result_sizes: [21, 23], hidden: false }
      ])

      subject.count_query 'bar bar', 0

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 2, last_result_sizes: [21, 23], hidden: false },
        { query: 'bar bar', count: 1, last_result_sizes: [0], hidden: false }
      ])

      subject.count_query 'moo', 4

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 2, last_result_sizes: [21, 23], hidden: false },
        { query: 'bar bar', count: 1, last_result_sizes: [0], hidden: false },
        { query: 'moo', count: 1, last_result_sizes: [4], hidden: false }
      ])

      subject.count_query 'moo', 3
      subject.count_query 'moo', 7
      subject.count_query 'moo', 10

      expect(subject.query_stats).to eq([
        { query: 'moo', count: 4, last_result_sizes: [3, 7, 10], hidden: false },
        { query: 'foo', count: 2, last_result_sizes: [21, 23], hidden: false },
        { query: 'bar bar', count: 1, last_result_sizes: [0], hidden: false }
      ])

      subject.mark_hidden 'foo'

      expect(subject.query_stats).to eq([
        { query: 'moo', count: 4, last_result_sizes: [3, 7, 10], hidden: false },
        { query: 'foo', count: 2, last_result_sizes: [21, 23], hidden: true },
        { query: 'bar bar', count: 1, last_result_sizes: [0], hidden: false }
      ])
    end
  end

end
