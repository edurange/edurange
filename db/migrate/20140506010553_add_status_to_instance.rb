class AddStatusToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :status, :integer, default: 0
  end
end
