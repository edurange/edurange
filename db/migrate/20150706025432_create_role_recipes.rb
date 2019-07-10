class CreateRoleRecipes < ActiveRecord::Migration[4.2]
  def change
    create_table :role_recipes do |t|
      t.references :role, index: true
      t.references :recipe, index: true
      t.timestamps null: false
    end
  end
end
