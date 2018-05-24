module HashUtils
  extend self

  def initialize_hash_with_keys_with_defaults keys
    keys.each_with_object({}) do |d, obj|
      obj[d] = yield
    end
  end

  def deep_convert_values_of_type hash, matching_type, &block
    hash.deep_merge(hash) do |_, _, v|
      if v.is_a? matching_type
        block.call v
      else
        v
      end
    end
  end
end
