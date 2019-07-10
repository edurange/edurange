class AddCustomToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :custom, :boolean
  end
end
