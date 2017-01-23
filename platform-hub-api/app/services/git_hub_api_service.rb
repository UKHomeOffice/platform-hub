class GitHubApiService

  def initialize options={}
    @client = Octokit::Client.new(options)
  end

  def access_token=(access_token)
    @client.access_token = access_token
  end

  def authorize_url client_id:, scope:, redirect_uri:, state:
    @client.authorize_url(client_id, scope: scope, redirect_uri: redirect_uri, state: state)
  end

  def user
    @client.user
  end

end
