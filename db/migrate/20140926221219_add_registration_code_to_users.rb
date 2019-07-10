class AddRegistrationCodeToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :registration_code, :string
  end
end
