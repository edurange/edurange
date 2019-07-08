class AddIdToBashHistories < ActiveRecord::Migration
  def change
  	add_column :bash_histories, :id, :primary_key
  end
end
