class AddScenarioidToGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :groups, :scenario_id, :integer
  end

  def down
    remove_column :groups, :scenario_id
  end
end
