class AddModifiedToScenario < ActiveRecord::Migration[4.2]
  def change
  	add_column :scenarios, :modified, :boolean, default: :false
  end
end
