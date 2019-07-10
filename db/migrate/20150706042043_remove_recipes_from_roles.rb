class RemoveRecipesFromRoles < ActiveRecord::Migration[4.2]
  def change
  	remove_column :roles, :recipes, :string
  end
end
