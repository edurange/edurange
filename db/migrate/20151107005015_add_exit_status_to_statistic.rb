class AddExitStatusToStatistic < ActiveRecord::Migration[4.2]
  def change
    add_column :statistics, :exit_status, :string
  end
end
