class AddOutputToBashHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :bash_histories, :output, :string
  end
end
