class AddStatusToSubnet < ActiveRecord::Migration[4.2]
  def change
    add_column :subnets, :status, :integer, default: 0
  end
end
