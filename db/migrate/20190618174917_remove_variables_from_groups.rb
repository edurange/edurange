class RemoveVariablesFromGroups < ActiveRecord::Migration[4.2]
  def change
    remove_column :groups, :variables
  end
end
