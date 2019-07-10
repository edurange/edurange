class CreateClouds < ActiveRecord::Migration[4.2]
  def change
    create_table :clouds do |t|
      t.string :name, required: true
      t.string :cidr_block, required: true
      t.string :driver_id
      t.references :scenario, index: true

      t.timestamps
    end
  end
end
