class AddForeignKeyRelations < ActiveRecord::Migration[4.2]
  def up
    fks = [
      ['clouds',          'scenario_id', 'scenarios', 'id'],
      ['questions',       'scenario_id', 'scenarios', 'id'],
      ['groups',          'scenario_id', 'scenarios', 'id'],
      ['recipes',         'scenario_id', 'scenarios', 'id'],
      ['subnets',         'cloud_id',    'clouds',    'id'],
      ['instances',       'subnet_id',   'subnets',   'id'],
      ['role_recipes',    'recipe_id',   'recipes',   'id'],
      ['instance_groups', 'group_id',    'groups',    'id'],
      ['instance_groups', 'instance_id', 'instances', 'id'],
      ['instance_roles',  'role_id',     'roles',     'id'],
      ['instance_roles',  'instance_id', 'instances', 'id'],
    ]

    fks.each do |line|
      source_table, source_column, target_table, target_column = line
      execute "DELETE FROM #{source_table} WHERE #{source_column} NOT IN (SELECT #{target_column} FROM #{target_table})"
      change_column_null(source_table, source_column, false)
      add_foreign_key(source_table, target_table, on_delete: :cascade, name: "fk_#{source_table}_#{target_table}")
    end

    execute "UPDATE players SET user_id = NULL WHERE user_id NOT IN (SELECT id FROM users)"
    add_foreign_key(:players, :users, on_delete: :nullify, name: 'fk_players_users')

    execute "UPDATE players SET student_group_id = NULL WHERE student_group_id NOT IN (SELECT id FROM student_groups)"
    add_foreign_key(:players, :student_groups, on_delete: :nullify, name: 'fk_players_student_groups')

    execute "DELETE FROM players WHERE group_id NOT IN (SELECT id FROM groups)"
    add_foreign_key(:players, :groups, on_delete: :cascade, name: 'fk_players_groups')
  end
end
