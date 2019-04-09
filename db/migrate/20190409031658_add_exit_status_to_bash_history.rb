class AddExitStatusToBashHistory < ActiveRecord::Migration
  def change
    add_column :bash_histories, :exit_status, :integer
  end
end
