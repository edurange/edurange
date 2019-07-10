class AddVariablesToGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :groups, :variables, :string
  end
end
