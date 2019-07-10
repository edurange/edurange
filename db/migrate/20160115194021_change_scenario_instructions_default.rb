class ChangeScenarioInstructionsDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :scenarios, :instructions, ""
  end

  def down
    change_column_default :scenarios, :instructions, nil
  end
end
