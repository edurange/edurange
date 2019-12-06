class AddTimeToBashHistories < ActiveRecord::Migration[5.2]
  def change
    add_column :bash_histories, :time, :int
  end
end
