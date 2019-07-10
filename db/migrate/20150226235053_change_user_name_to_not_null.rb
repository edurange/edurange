class ChangeUserNameToNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :users, :name, false
  end
end
