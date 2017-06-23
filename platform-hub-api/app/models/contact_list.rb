class ContactList < ApplicationRecord

  ID_REGEX = /[a-zA-Z][\w-]*/

  include Audited

  audited descriptor_field: :id

  validates :id,
    format: {
      with: ID_REGEX,
      message: "should consist of letters, numbers, underscores and dashes (starting with a letter)"
    }

end
