class AddScoringUrlToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :scoring_url, :string
  end
end
