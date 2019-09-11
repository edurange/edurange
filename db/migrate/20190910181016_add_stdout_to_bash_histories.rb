class AddStdoutToBashHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :bash_histories, :stdout, :string
  end
end
