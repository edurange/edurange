class AddLogToClouds < ActiveRecord::Migration[4.2]
  def change
    add_column :clouds, :log, :string, default: ""
  end
end
