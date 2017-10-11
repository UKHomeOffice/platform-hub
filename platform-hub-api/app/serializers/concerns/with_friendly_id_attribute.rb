module WithFriendlyIdAttribute
  extend ActiveSupport::Concern

  included do

    attribute :id do
      object.friendly_id
    end

  end

end
