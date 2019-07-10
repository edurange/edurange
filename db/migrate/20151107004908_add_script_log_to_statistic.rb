class AddScriptLogToStatistic < ActiveRecord::Migration[4.2]
  def change
    add_column :statistics, :script_log, :string
  end
end
