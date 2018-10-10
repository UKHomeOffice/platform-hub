require 'rails_helper'

RSpec.describe HelpController, type: :controller do

  include_context 'help search helpers'

  describe 'GET #search' do
    it_behaves_like 'unauthenticated not allowed' do
      before do
        get :search
      end
    end

    it_behaves_like 'authenticated' do

      context 'when no query is provided' do
        it 'should return an empty response' do
          get :search
          expect(response.status).to be 204
        end
      end

      context 'when a query is provided' do

        let(:query) { 'bar' }

        let :results do
          [
            { 'foo' => 'bar '},
            { 'bar' => 'baz '},
          ]
        end

        before do
          expect(help_search_service_instance).to receive(:search)
            .with(query)
            .and_return(results)
        end

        context 'with ignore_for_stats not passed in' do
          before do
            expect(HelpSearchStatsService).to receive(:count_query)
              .with(query, results.size)
          end

          it 'should return the results as expected' do
            get :search, params: { q: query }
            expect(response).to be_success
            expect(json_response).to eq results
          end
        end

        context 'with ignore_for_stats passed in' do
          before do
            expect(HelpSearchStatsService).to receive(:count_query)
              .with(query, results.size)
              .never
          end

          it 'should return the results as expected' do
            get :search, params: { q: query, ignore_for_stats: true }
            expect(response).to be_success
            expect(json_response).to eq results
          end
        end

      end

    end
  end

end
