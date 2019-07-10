class CreateVariablesTables < ActiveRecord::Migration[4.2]
  def change
    create_table :variable_templates do |table|
      table.references :group,    foreign_key: { on_delete: :cascade }
      table.references :scenario, foreign_key: { on_delete: :cascade }

      table.string :name, null: false
      table.string :type, null: false
      table.string :value
    end

    add_index :variable_templates, [:group_id,    :name], unique: true
    add_index :variable_templates, [:scenario_id, :name], unique: true

    create_table :variables do |table|
      table.references :variable_template, null: false, foreign_key: {on_delete: :cascade}
      table.references :player,                         foreign_key: {on_delete: :cascade}
      table.references :scenario,                       foreign_key: {on_delete: :cascade}
      table.string     :value,             null: false
    end

    add_index :variables, [:variable_template_id, :player_id],   unique: true
    add_index :variables, [:variable_template_id, :scenario_id], unique: true
  end
end
