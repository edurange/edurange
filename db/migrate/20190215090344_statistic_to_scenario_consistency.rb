class StatisticToScenarioConsistency < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE statistics SET scenario_id = NULL WHERE scenario_id NOT IN (SELECT id FROM scenarios)"
    add_foreign_key :statistics, :scenarios, on_delete: :nullify
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
