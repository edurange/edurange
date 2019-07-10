class AddLogToInstances < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :log, :string, default: ""
  end
end
