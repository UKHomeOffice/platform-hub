module ValidateHashes
  extend ActiveSupport::Concern

  # Uses https://github.com/deseretbook/classy_hash for the schema definition
  # and validation.
  #
  # NOTE: Doesn't currently do strict matching of schema to data. This means
  # your Hash can contain fields not defined in the schema, and only those
  # defined in the schema are actually checked. This is more lenient and
  # forgiving and allows you to do partial validation of hashes, which is
  # essential for forward compatability. Strict check _can_ be easily added
  # using the `strict: true` option for ClassyHash, but we should probably not
  # do this!

  CONFIG_ENTRY_ALLOWED_KEYS = [
    :schema,
    :unique_checks
  ]

  class_methods do

    # Example usage:
    #
    #   validate_hashes(
    #     field_one: {
    #       schema: <ClassyHash schema>,
    #       unique_checks: [
    #         { array_path: [ :foo, :bar ], obj_key: :id },
    #         { array_path: :baz }
    #       ]
    #     },
    #     field_two: { schema: <ClassyHash schema> }
    #   )
    #
    # NOTE: any properties used in the `unique_checks` (via the `array_path`)
    # are expected to be required properties, and so will cause an error if nil
    # in the actual data (regardless of whether they are marked as :optional /
    # NilClass in the ClassyHash schema).
    def validate_hashes config
      mattr_accessor :validate_hashes_config, instance_writer: false

      validate :validate_hashes_validation

      # Check that config provided is valid
      config_ok = config.is_a?(Hash) &&
        config.keys.any? &&
        config.values.all? { |h| (h.keys - CONFIG_ENTRY_ALLOWED_KEYS).empty? }

      unless config_ok
        raise 'Invalid config provided to validate_hashes'
      end

      self.validate_hashes_config = config
    end

  end

  private

  def validate_hashes_validation
    self.validate_hashes_config.each do |name, config|
      validate_hashes_validate_field name, config
    end
  end

  def validate_hashes_validate_field name, config
    value = self.send name
    unless value.nil?
      if config[:schema]
        hash_errors = []

        success = ClassyHash.validate(
          value,
          config[:schema],
          errors: hash_errors,
          raise_errors: false,
          full: true
        )

        unless success
          hash_errors.each do |e|
            self.errors.add(name, "- #{e[:full_path]} should be #{e[:message]}")
          end
        end
      end

      # Only continue with unique checks if we don't have any errors just yet
      if self.errors[name].empty? && config[:unique_checks]
        config[:unique_checks].each do |uc|
          path = Array(uc[:array_path])
          array = value.dig(*path)
          if array.nil?
            self.errors.add(name, "- #{path.join('.')} is nil when it shouldn't be")
          else
            obj_key = uc[:obj_key]
            items_to_check = if obj_key
              array.map { |i| i[obj_key] }
            else
              array.clone
            end.flatten

            if items_to_check.length != items_to_check.uniq.length
              self.errors.add(name, "- #{path.join('.')} contains duplicate values#{obj_key ? ' for property: ' + obj_key.to_s : ''}")
            end
          end
        end
      end
    end
  end

end
