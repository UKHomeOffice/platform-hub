class AuthorizedController < AuthenticatedController

  include CanCan::ControllerAdditions

  check_authorization

  rescue_from CanCan::AccessDenied do |exception|
    logger.warn "AUTHORIZATION FAIL: user #{current_user.id} (#{current_user.name}) tried to a perform an action they are not authorized for: action = #{exception.action}, subject = #{exception.subject}"
    render_error 'You are not authorized to perform that action', :forbidden
  end

end
