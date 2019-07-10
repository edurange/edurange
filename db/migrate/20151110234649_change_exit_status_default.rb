class ChangeExitStatusDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :statistics, :exit_status, ""
  end

  def down
    change_column_default :statistics, :exit_status, nil
  end
end
