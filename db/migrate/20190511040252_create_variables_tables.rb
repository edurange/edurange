class CreateVariablesTables < ActiveRecord::Migration
  def change

    create_table :variables do |table|
      table.string :name, null: false
      table.string :type, null: false
      table.string :value
    end

    create_table :instances_variables, id: false do |table|
      table.references :instance, foreign_key: { on_delete: :cascade }
      table.references :variable, foreign_key: { on_delete: :cascade }
    end
    execute 'ALTER TABLE instances_variables ADD PRIMARY KEY (instance_id, variable_id);'

    create_table :players_variables, id: false do |table|
      table.references :player, foreign_key: { on_delete: :cascade }
      table.references :variable, foreign_key: { on_delete: :cascade }
    end
    execute 'ALTER TABLE players_variables ADD PRIMARY KEY (player_id, variable_id);'

  end
end
