class AddCompletedServicesOnboardingToUserFlags < ActiveRecord::Migration[5.0]
  def change
    add_column :user_flags, :completed_services_onboarding, :boolean, default: false
  end
end
