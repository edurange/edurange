class AddAnswersToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :answers, :text, required: true
  end
end