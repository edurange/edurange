class CreateStatistics < ActiveRecord::Migration[4.2]
  def change
    create_table :statistics do |t|
      t.belongs_to :user
      t.timestamps null: false
      t.string :bash_histories, :default => ''

      t.text :bash_analytics, :default => [].to_yaml
      t.string :scenario_name
      t.datetime :scenario_created_at
    end
  end
end
