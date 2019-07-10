class RenameScoringurlstoScoringpages < ActiveRecord::Migration[4.2]
  def change
    rename_column :scenarios, :scoring_urls, :scoring_pages
  end
end
