class ChangeScriptLogDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :statistics, :script_log, ""
  end

  def down
    change_column_default :statistics, :script_log, nil
  end
end
