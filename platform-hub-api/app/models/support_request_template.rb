class SupportRequestTemplate < ApplicationRecord

  include FriendlyId
  include Audited
  include ValidateHashes

  audited descriptor_field: :shortname

  friendly_id :shortname, :use => :slugged

  def should_generate_new_friendly_id?
    shortname_changed? || super
  end

  validates :shortname,
    presence: true,
    uniqueness: { case_sensitive: false }

  validates :git_hub_repo,
    presence: true

  validates :title,
    presence: true

  validates :description,
    presence: true

  validates :form_spec,
    presence: true

  validates :git_hub_issue_spec,
    presence: true


  class << self
    attr_reader :form_field_types
  end

  @form_field_types = FormFieldsService.all_types

  validate_hashes(
    form_spec: {
      schema: {
        'help_text' => [:optional, String],
        'fields' => [[
          FormFieldsService.field_schema(SupportRequestTemplate.form_field_types)
        ]]
      },
      unique_checks: [
        { array_path: 'fields', obj_key: 'id' }
      ]
    },
    git_hub_issue_spec: {
      schema: {
        'title_text' => String,
        'body_text_preamble' => [:optional, String]
      }
    }
  )

  def self.git_hub_repos
    SupportRequestTemplate.pluck(:git_hub_repo).uniq.sort
  end

end
