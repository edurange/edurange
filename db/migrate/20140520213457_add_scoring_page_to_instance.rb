class AddScoringPageToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :scoring_page, :string
  end
end
