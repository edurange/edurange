class ChangeScriptLogPageDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :instances, :script_log_page, ""
  end

  def down
  	change_column_default :instances, :script_log_page, nil
  end
end
