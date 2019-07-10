class ChangeExitStatusPageDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :instances, :exit_status_page, ""
  end

  def down
    change_column_default :instances, :exit_status_page, nil
  end
end
