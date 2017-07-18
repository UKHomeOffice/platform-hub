class AnnouncementTemplate < ApplicationRecord

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

  validates :description,
    presence: true

  validates :spec,
    presence: true

  class << self
    attr_reader :form_field_types
  end

  @form_field_types = FormFieldsService.validate_types(Set[
    'text',
    'textarea',
    'number',
    'select',
    'email',
    'url'
  ])

  validate_hashes(
    spec: {
      schema: {
        'fields' => [[
          FormFieldsService.field_schema(AnnouncementTemplate.form_field_types)
        ]],
        'templates' => {
          'title' => String,
          'on_hub' => String,
          'email_html' => String,
          'email_text' => String,
          'slack' => String
        }
      },
      unique_checks: [
        { array_path: 'fields', obj_key: 'id' }
      ]
    }
  )

end
