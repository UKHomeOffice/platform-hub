module AuditContext
  extend ActiveSupport::Concern

  def audit_context
    request = self.try(:request)

    {
      user: self.try(:current_user),
      remote_ip: request ? request.try(:remote_ip) : nil,
      request_uuid: request ? request.try(:uuid) : nil
    }
  end

end
