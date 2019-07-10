class CreateInstanceGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :instance_groups do |t|
      t.references :group, index: true
      t.references :instance, index: true
      t.boolean :administrator

      t.timestamps
    end
  end
end
