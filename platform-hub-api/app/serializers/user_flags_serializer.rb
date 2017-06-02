class UserFlagsSerializer < BaseSerializer

  UserFlags.flag_names.each do |f|
    attribute f do
      !!object.send(f)
    end
  end

end
