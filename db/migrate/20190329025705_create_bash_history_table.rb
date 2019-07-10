class CreateBashHistoryTable < ActiveRecord::Migration[4.2]
  def change
    create_table :bash_histories, id: false do |table|
      table.integer  :player_id, null: false
      table.integer  :instance_id, null: false
      table.datetime :performed_at, null: false
      table.string   :command, null: false
    end
    add_foreign_key :bash_histories, :players, name: 'fk_bash_histories_players'
    add_foreign_key :bash_histories, :instances, name: 'fk_bash_histories_instances'
  end
end
