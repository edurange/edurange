class DropInternalScenarioTables < ActiveRecord::Migration[5.2]
  def change
    drop_table :role_recipes
    drop_table :recipes
    drop_table :instance_roles
    drop_table :roles

    add_reference :instances, :scenario
    add_foreign_key :instances, :scenarios
    execute "update instances set scenario_id = scenarios.id from subnets, clouds, scenarios where subnets.id = instances.subnet_id and clouds.id = subnets.cloud_id and scenarios.id = clouds.scenario_id"

    change_column_null :instances, :scenario_id, false
    change_column_null :instances, :created_at, false
    change_column_null :instances, :updated_at, false
    change_column_null :instances, :name, false
    change_column_null :instances, :status, false

    remove_column :instances, :driver_id
    remove_column :instances, :ip_address
    remove_column :instances, :os
    remove_column :instances, :internet_accessible
    remove_column :instances, :scoring_url
    remove_column :instances, :scoring_page
    remove_column :instances, :log
    remove_column :instances, :subnet_id
    remove_column :instances, :ip_address_dynamic
    remove_column :instances, :boot_code
    remove_column :instances, :uuid

    remove_column :scenarios, :log
    remove_column :scenarios, :answers
    remove_column :scenarios, :com_page
    remove_column :scenarios, :modified
    remove_column :scenarios, :modifiable
    remove_column :scenarios, :boot_code
    remove_column :scenarios, :archived
    remove_column :scenarios, :scoring_pages
    remove_column :scenarios, :answers_url
    remove_column :scenarios, :scoring_pages_content

    drop_table :subnets
    drop_table :clouds
  end
end
