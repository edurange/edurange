class AddInstructionsToScenario < ActiveRecord::Migration[4.2]
    def up
    add_column :scenarios, :instructions, :string
  end

  def down
    remove_column :scenarios, :instructions
  end
end
