module FormFieldsService
  extend self

  ALL_ALLOWED_TYPES = Set[
    'text',
    'textarea',
    'number',
    'checkbox',
    'select',
    'datetime-local',
    'email',
    'url'
  ].freeze

  def all_types
    ALL_ALLOWED_TYPES
  end

  def validate_types types
    if types.proper_subset?(ALL_ALLOWED_TYPES)
      types
    else
      raise('Invalid form field type(s) specified')
    end
  end

  # TODO: some of the fields below need conditional checks for presence (e.g.
  # the `options` field should only be present if `field_type` is 'select').
  # A request has been made to the ClassyHash library to support this:
  # https://github.com/deseretbook/classy_hash/issues/22
  def field_schema allowed_types
    {
      'id' => /\A\w+\z/i,
      'label' => String,
      'field_type' => allowed_types,
      'required' => TrueClass,
      'placeholder' => [:optional, String],
      'help_text' => [:optional, String],
      'options' => [:optional, String],
      'multiple' => [:optional, TrueClass]
    }
  end
end
