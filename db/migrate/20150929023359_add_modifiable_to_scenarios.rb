class AddModifiableToScenarios < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :modifiable, :boolean, default: false
  end
end
