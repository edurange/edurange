class AddUseridToScenarios < ActiveRecord::Migration[4.2]
  def up
    add_column :scenarios, :user_id, :integer
  end

  def down
    remove_column :scenarios, :user_id
  end
end
