class AddLogToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :log, :text, default: ""
  end
end
