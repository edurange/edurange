class AddScriptLogPageToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :script_log_page, :string
  end
end
