class CreateScenarios < ActiveRecord::Migration[4.2]
  def change
    create_table :scenarios do |t|
      t.string :name, required: true
      t.string :description, required: true

      t.timestamps
    end
  end
end
