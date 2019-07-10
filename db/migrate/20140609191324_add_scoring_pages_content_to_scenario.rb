class AddScoringPagesContentToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :scoring_pages_content, :text, default: ""
  end
end
