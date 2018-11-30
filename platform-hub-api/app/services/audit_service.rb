module AuditService

  def self.log context: {}, action: nil, auditable: nil, associated: nil, comment: nil, data: nil
    begin
      Audit.create!(
        action: action,
        auditable: auditable,
        associated: associated,
        user: context[:user],
        comment: comment,
        data: data,
        remote_ip: context[:remote_ip],
        request_uuid: context[:request_uuid]
      )
    rescue => e
      Rails.logger.error "Failed to log audit - exception: type = #{e.class.name}, message = #{e.message}, backtrace = #{e.backtrace.join(" -- ")}"
    end
  end

end
