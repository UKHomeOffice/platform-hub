class AddIndexesToDelayedJobs < ActiveRecord::Migration[5.0]
  def change
    add_index :delayed_jobs, :queue
  end
end
