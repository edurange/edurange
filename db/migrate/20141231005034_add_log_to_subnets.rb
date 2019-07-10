class AddLogToSubnets < ActiveRecord::Migration[4.2]
  def change
    add_column :subnets, :log, :string, default: ""
  end
end
