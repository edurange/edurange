class CreateInstances < ActiveRecord::Migration[4.2]
  def change
    create_table :instances do |t|
      t.string :name, required: true
      t.string :ip_address, required: true
      t.string :driver_id
      t.string :cookbook_url, required: true
      t.string :os, required: true
      t.boolean :internet_accessible, required: true
      t.references :subnet, index: true

      t.timestamps
    end
  end
end
