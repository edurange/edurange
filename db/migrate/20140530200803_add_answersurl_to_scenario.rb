class AddAnswersurlToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :answers_url, :string
  end
end
