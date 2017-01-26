module AdminAuthorizationHelpers

  # The helpers here need to be used within the shared examples defined in
  # authentication_helpers

  RSpec.shared_context 'admin authorization helpers' do

    def make_current_user_admin
      user = @controller.create_or_fetch_user auth_token
      user.make_admin!
    end

  end

  RSpec.shared_examples 'not an admin so forbidden' do
    it 'will return a 403 Forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  RSpec.shared_examples 'an admin' do
    include_context 'admin authorization helpers'

    before do
      make_current_user_admin
    end
  end

end
