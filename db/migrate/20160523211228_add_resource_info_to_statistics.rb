class AddResourceInfoToStatistics < ActiveRecord::Migration[4.2]
  def change
    add_column :statistics, :resource_info, :string
  end
end
