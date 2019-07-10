class AddArchivedToScenarios < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :archived, :boolean, null: false, default: false
  end
end
