module FeatureFlagService
  extend self

  # Feature flags data is stored in HashRecord as:
  # data: {
  #   'your_feature_flag_name': Bool,
  #   ...
  # }

  def all
    feature_flags.data
  end

  def create_or_update(flag, value)
    f = feature_flags
    f.with_lock do
      f.data[flag.to_s] = ActiveRecord::Type::Boolean.new.deserialize(value)
      f.save!
      "Created/updated feature flags"
    end
  end

  def delete(flag)
    f = feature_flags
    f.with_lock do
      f.data.reject! {|k,_| k == flag.to_s}
      f.save!
      "Deleted feature flag"
    end
  end

  def is_enabled?(flag)
    feature_flags.data.with_indifferent_access[flag] || false
  end

  def all_enabled?(flags)
    return flags.all?(&method(:is_enabled?))
  end

  private

  def feature_flags
    HashRecord.general.find_or_create_by!(id: 'feature_flags') do |r|
      r.data = {}
    end
  end
end
