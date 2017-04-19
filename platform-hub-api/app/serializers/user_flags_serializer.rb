class UserFlagsSerializer < ActiveModel::Serializer

  UserFlags.flag_names.each do |f|
    attribute f do
      !!object.send(f)
    end
  end

end
