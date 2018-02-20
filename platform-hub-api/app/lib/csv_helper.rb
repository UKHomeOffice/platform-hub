module CSVHelper

  class ColumnError < StandardError
  end

  # expected_columns should be a Hash where:
  # - key = column name exactly as it should be in the header
  # - value = the index in the header
  def self.validate_columns header, expected_columns
    expected_columns.each do |(name, ix)|
      got = header[ix]
      if got != name.to_s
        raise ColumnError, "unexpected column at index #{ix} of header - should be '#{name.to_s}' but got '#{got}'"
      end
    end
  end

end
