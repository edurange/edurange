class AddScoringurlsToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :scoring_urls, :string
  end
end
