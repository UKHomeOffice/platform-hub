class SupportRequestTemplateSerializer < BaseSerializer

  include WithFriendlyIdAttribute

  attributes(
    :shortname,
    :git_hub_repo,
    :title,
    :description,
    :user_scope,
    :created_at,
    :updated_at
  )

  attributes :form_spec
  attributes :git_hub_issue_spec

end
