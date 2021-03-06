module AuthenticationHelpers

  RSpec.shared_context 'authentication helpers' do

    let :auth_token do
      test_auth_token
    end

    let :current_user_id do
      '7ea9251a-492e-42c3-90cb-d8e5a1d99005'
    end

    let :current_user do
      AuthUserService.get test_auth_payload
    end

    def test_auth_token
      @test_auth_token ||= build_auth_token(test_auth_payload)
    end

    def test_auth_payload
      @test_auth_payload ||= Hashie::Mash.new({
        jti: '8db593b2-b40f-4e85-9fad-91932dd55430',
        exp: 1.week.from_now.to_i,
        nbf: 0,
        iat: 1.hour.ago.to_i,
        iss: 'https://sso.example.org',
        aud: 'platform-hub',
        sub: current_user_id,
        typ: 'Bearer',
        auth_time: 1.hour.ago.to_i,
        session_state: 'c340f212-09e2-41a2-a4bd-602b8103fb68',
        acr: '1',
        client_session: 'd19ef6bc-5532-4d4b-908f-2efbe75e43e1',
        'allowed-origins': [ '*' ],
        name: 'Jane Doe',
        preferred_username: 'jane_doe',
        given_name: 'Jane',
        family_name: 'Doe',
        email: 'jane.doe@example.org'
      })
    end

    private

    def build_auth_token payload
      JWT.encode payload, nil, 'none', { typ: 'JWT' }
    end

  end

  RSpec.shared_examples 'unauthenticated not allowed' do
    it 'will return a 401 Unauthorized' do
      expect(response).to have_http_status(401)
    end
  end

  RSpec.shared_examples 'authenticated' do
    include_context 'authentication helpers'

    before do
      @request.set_header 'HTTP_AUTHORIZATION', "Bearer #{auth_token}"
    end
  end

end
