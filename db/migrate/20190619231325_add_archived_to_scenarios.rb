class AddArchivedToScenarios < ActiveRecord::Migration
  def change
    add_column :scenarios, :archived, :boolean, null: false, default: false
  end
end
