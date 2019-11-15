class AddCwdToBashHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :bash_histories, :cwd, :string
  end
end
