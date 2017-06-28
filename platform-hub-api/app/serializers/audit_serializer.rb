class AuditSerializer < BaseSerializer
  attributes(
    :action,
    :user_name,
    :comment,
    :remote_ip,
    :created_at,
  )
end
