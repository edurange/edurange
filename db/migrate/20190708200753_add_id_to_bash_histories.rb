class AddIdToBashHistories < ActiveRecord::Migration[4.2]
  def change
  	add_column :bash_histories, :id, :primary_key
  end
end
