require 'rails_helper'

RSpec.describe HelpSearchStatsService, type: :service do

  let(:key) { HelpSearchStatsService::KEY }

  describe 'counting queries and getting query stats' do
    it 'should keep a record of query counts as well as last n result sizes per queries' do
      expect(subject.query_stats).to be_empty

      subject.count_query 'foo', 21

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 1, last_result_sizes: [21]}
      ])

      subject.count_query 'Foo ', 23

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 2, last_result_sizes: [21, 23]}
      ])

      subject.count_query 'bar bar', 0

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 2, last_result_sizes: [21, 23]},
        { query: 'bar bar', count: 1, last_result_sizes: [0]}
      ])

      subject.count_query 'moo', 4

      expect(subject.query_stats).to eq([
        { query: 'foo', count: 2, last_result_sizes: [21, 23]},
        { query: 'bar bar', count: 1, last_result_sizes: [0]},
        { query: 'moo', count: 1, last_result_sizes: [4]}
      ])

      subject.count_query 'moo', 3
      subject.count_query 'moo', 7
      subject.count_query 'moo', 10

      expect(subject.query_stats).to eq([
        { query: 'moo', count: 4, last_result_sizes: [3, 7, 10]},
        { query: 'foo', count: 2, last_result_sizes: [21, 23]},
        { query: 'bar bar', count: 1, last_result_sizes: [0]}
      ])
    end
  end

end
