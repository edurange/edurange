class DropInternalScenarioTables < ActiveRecord::Migration[5.2]
  def change

    # Add constraints to instances

    add_reference :instances, :scenario
    add_foreign_key :instances, :scenarios, name: 'fk_instances_scenarios'
    execute "update instances set scenario_id = scenarios.id from subnets, clouds, scenarios where subnets.id = instances.subnet_id and clouds.id = subnets.cloud_id and scenarios.id = clouds.scenario_id"

    change_column_null :instances, :scenario_id, false
    change_column_null :instances, :created_at, false
    change_column_null :instances, :updated_at, false
    change_column_null :instances, :name, false
    change_column_null :instances, :status, false

    rename_column :instances, :ip_address, :ip_address_private

    # Remove unnesacary instances columns

    remove_column :instances, :driver_id
    remove_column :instances, :ip_address_dynamic
    remove_column :instances, :os
    remove_column :instances, :internet_accessible
    remove_column :instances, :scoring_url
    remove_column :instances, :scoring_page
    remove_column :instances, :log
    remove_column :instances, :subnet_id
    remove_column :instances, :boot_code
    remove_column :instances, :uuid

    # Add constraints to scenarios

    change_column_null :scenarios, :name, false

    ## I don't think replacing nulls with empty strings is sensible.
    # execute "update scenarios set description = '' where description is null";
    ## There was exactly one scenario in the database where with a null description.
    # change_column_null :scenarios, :description, false
    ## Leaving this for the next person to decide.

    change_column_null :scenarios, :user_id, false

    scenarios = select_all("select id from scenarios where uuid is null")
    scenarios.each do |scenario|
      update("update scenarios set uuid = #{ActiveRecord::Base.connection.quote(SecureRandom.uuid)} where id = #{ActiveRecord::Base.connection.quote(scenario['id'])}")
    end

    change_column_null :scenarios, :uuid, false
    change_column_null :scenarios, :location, false
    change_column_null :scenarios, :status, false
    change_column_null :scenarios, :created_at, false
    change_column_null :scenarios, :updated_at, false

    add_foreign_key :scenarios, :users, name: 'fk_scenarios_users'

    # Remove unnesacary instances columns

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

    # Drop scenario "internal" tables
    # The point is to reduce the size of the interface between the
    # scenario provider/backend and edurange-server

    drop_table :role_recipes
    drop_table :recipes
    drop_table :instance_roles
    drop_table :roles
    drop_table :subnets
    drop_table :clouds

    # Also these tables just are not used anymore
    drop_table :tutorials
    drop_table :statistics
  end
end
