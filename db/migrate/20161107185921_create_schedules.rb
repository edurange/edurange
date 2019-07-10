class CreateSchedules < ActiveRecord::Migration[4.2]
  def change
    create_table :schedules do |t|
      t.integer :user_id
      t.string :scenario
      t.string :scenario_location
      t.string :uuid
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps null: false
    end
  end
end
