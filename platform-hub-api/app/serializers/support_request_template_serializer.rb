class SupportRequestTemplateSerializer < ActiveModel::Serializer
  attributes(
    :id,
    :shortname,
    :git_hub_repo,
    :title,
    :description,
    :created_at,
    :updated_at
  )

  attributes :form_spec
  attributes :git_hub_issue_spec

  def id
    object.friendly_id
  end
end
