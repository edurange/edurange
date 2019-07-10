class AddUuidToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :uuid, :string
  end
end
