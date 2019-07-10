class AddStatusToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :status, :integer, default: 0
  end
end
