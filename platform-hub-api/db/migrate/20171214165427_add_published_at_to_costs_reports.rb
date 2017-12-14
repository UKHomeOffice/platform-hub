class AddPublishedAtToCostsReports < ActiveRecord::Migration[5.0]
  def change
    add_column :costs_reports, :published_at, :datetime, null: true
  end
end
