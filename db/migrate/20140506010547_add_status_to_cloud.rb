class AddStatusToCloud < ActiveRecord::Migration[4.2]
  def change
    add_column :clouds, :status, :integer, default: 0
  end
end
