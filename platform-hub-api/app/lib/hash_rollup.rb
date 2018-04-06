module HashRollup
  extend self

  def rollup data, into
    raise ArgumentError, "arguments must be Hashes" unless data.is_a?(Hash) && into.is_a?(Hash)

    into.merge(data) do |key, current_val, new_val|
      if current_val.class.name != new_val.class.name
        raise "Mismatch in types detected! Key = #{key}, current value type = #{current_val.class.name}, new value type = #{new_val.class.name}"
      end

      if current_val.is_a?(Hash)
        rollup new_val, current_val
      elsif current_val.is_a?(String)
        new_val
      else
        current_val + new_val
      end
    end
  end

end
