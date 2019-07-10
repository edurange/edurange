class CreateRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :roles do |t|
      t.string :name, required: true
      t.string :packages
      t.string :recipes

      t.timestamps
    end
  end
end
