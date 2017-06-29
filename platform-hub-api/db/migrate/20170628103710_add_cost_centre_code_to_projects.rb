class AddCostCentreCodeToProjects < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :cost_centre_code, :string
  end
end
