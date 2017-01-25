class AuthenticatedController < ApplicationController
  include Authentication

  before_action :require_authentication
end
