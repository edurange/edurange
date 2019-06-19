class RemoveVariablesFromGroups < ActiveRecord::Migration
  def change
    remove_column :groups, :variables
  end
end
