class CreateInstanceRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :instance_roles do |t|
      t.references :instance, index: true
      t.references :role, index: true

      t.timestamps
    end
  end
end
