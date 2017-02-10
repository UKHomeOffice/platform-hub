class AuthenticatedController < ApplicationController

  include Authentication
  include AuditContext

  before_action :require_authentication

end
