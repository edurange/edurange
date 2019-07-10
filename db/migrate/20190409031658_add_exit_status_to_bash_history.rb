class AddExitStatusToBashHistory < ActiveRecord::Migration[4.2]
  def change
    add_column :bash_histories, :exit_status, :integer
  end
end
