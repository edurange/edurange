class AddOrganizationToUsers < ActiveRecord::Migration[4.2]
  def up
    add_column :users, :organization, :string
  end

  def down
    remove_column :users, :organization
  end
end
