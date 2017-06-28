class AddAgreedToTermsOfServiceToUserFlags < ActiveRecord::Migration[5.0]
  def change
    add_column :user_flags, :agreed_to_terms_of_service, :boolean, default: false
  end
end
