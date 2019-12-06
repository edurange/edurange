class AddBeginToBashHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :bash_histories, :begin, :string
  end
end
