class ChangeScriptLogToNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :statistics, :script_log, ""
  end
end
