class AddScenarioToRole < ActiveRecord::Migration[4.2]
  def change
  	add_column :roles, :scenario_id, :integer
  end
end
