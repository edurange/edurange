class ChangeExitStatusToNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :statistics, :exit_status, ""
  end
end
