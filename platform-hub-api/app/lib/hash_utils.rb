module HashUtils
  extend self

  def initialize_hash_with_keys_with_defaults keys
    keys.each_with_object({}) do |d, obj|
      obj[d] = yield
    end
  end
end
