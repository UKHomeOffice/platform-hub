module AdminAuthorizationHelpers

  # The helpers here need to be used within the shared examples defined in
  # authentication_helpers

  # Hub admin

  RSpec.shared_context 'hub admin authorization helpers' do
    def make_current_user_admin
      user = @controller.create_or_fetch_user auth_token
      user.make_admin!
    end
  end

  RSpec.shared_examples 'not a hub admin so forbidden' do
    it 'will return a 403 Forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  RSpec.shared_examples 'a hub admin' do
    include_context 'hub admin authorization helpers'

    before do
      make_current_user_admin
    end
  end

  # Hub limited admin

  RSpec.shared_context 'hub limited admin authorization helpers' do
    def make_current_user_limited_admin
      user = @controller.create_or_fetch_user auth_token
      user.make_limited_admin!
    end
  end

  RSpec.shared_examples 'not a hub limited admin so forbidden' do
    it 'will return a 403 Forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  RSpec.shared_examples 'a hub limited admin' do
    include_context 'hub limited admin authorization helpers'

    before do
      make_current_user_limited_admin
    end
  end

end
