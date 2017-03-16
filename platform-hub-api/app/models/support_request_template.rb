class SupportRequestTemplate < ApplicationRecord

  include FriendlyId
  include Audited

  audited descriptor_field: :shortname

  friendly_id :shortname, :use => :slugged

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

  validate :check_schemas
  validate :check_form_spec

  class << self
    attr_reader :schemas, :form_field_types
  end

  @form_field_types = Set.new([
    'text',
    'textarea',
    'number',
    'checkbox',
    'select',
    'datetime-local',
    'email',
    'url'
  ]).freeze

  # TODO: some of the fields below need conditional checks for presence (e.g.
  # the `options` field within the `fields` list should only be present if
  # `field_type` is 'select').
  # A request has been made to the ClassyHash library to support this:
  # https://github.com/deseretbook/classy_hash/issues/22
  @schemas = {
    form_spec: {
      'help_text' => [:optional, String],
      'fields' => [[
        {
          'id' => /\w+/i,
          'label' => String,
          'field_type' => SupportRequestTemplate.form_field_types,
          'required' => TrueClass,
          'placeholder' => [:optional, String],
          'help_text' => [:optional, String],
          'options' => [:optional, String],
          'multiple' => [:optional, TrueClass]
        }
      ]]
    },
    git_hub_issue_spec: {
      'title_text' => String,
      'body_text_preamble' => [:optional, String]
    }
  }.freeze

  def self.git_hub_repos
    SupportRequestTemplate.pluck(:git_hub_repo).uniq.sort
  end

  private

  def check_schemas
    perform_hash_validation :form_spec, self.form_spec, SupportRequestTemplate.schemas[:form_spec]
    perform_hash_validation :git_hub_issue_spec, self.git_hub_issue_spec, SupportRequestTemplate.schemas[:git_hub_issue_spec]
  end

  def perform_hash_validation field_name, hash, schema
    hash_errors = []
    success = ClassyHash.validate(hash, schema, errors: hash_errors, raise_errors: false, full: true)
    unless success
      self.errors.add(field_name, hash_validation_errors_to_string(hash_errors))
    end
  end

  def hash_validation_errors_to_string errors
    errors.map do |e|
      "-- #{e[:full_path]} should be #{e[:message]}"
    end.join(' ')
  end

  def check_form_spec
    if self.form_spec
      fields = self.form_spec['fields']
      if fields && !fields.empty?
        uniq_ids = fields.map{|f| f['id']}.uniq
        if fields.length != uniq_ids.length
          self.errors.add(:form_spec, 'contains fields with duplicate IDs')
        end
      end
    end
  end

end
