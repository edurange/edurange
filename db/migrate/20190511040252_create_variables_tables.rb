class CreateVariablesTables < ActiveRecord::Migration
  def change
    create_table :variables do |table|
      table.references :player, foreign_key: { on_delete: :cascade }
      table.references :group, foreign_key: { on_delete: :cascade }
      table.boolean :template, null: false, default: true

      table.string :name, null: false
      table.string :type, null: false
      table.string :value
    end

    add_index :variables, [:group_id,    :name, :template], unique: true
    add_index :variables, [:player_id,   :name],            unique: true
  end
end
