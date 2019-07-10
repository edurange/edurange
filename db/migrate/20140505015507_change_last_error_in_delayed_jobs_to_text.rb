class ChangeLastErrorInDelayedJobsToText < ActiveRecord::Migration[4.2]
  def change
    change_column :delayed_jobs, :last_error, :text
  end
end
