class AddLocationToScenario < ActiveRecord::Migration[4.2]
  def change
  	add_column :scenarios, :location, :integer, default: 0
  	remove_column :scenarios, :custom
  end
end
