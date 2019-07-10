class AddScenarioIdToStatistics < ActiveRecord::Migration[4.2]
  def change
    add_column :statistics, :scenario_id, :integer
  end
end
