class AddCodelabToScenario < ActiveRecord::Migration[5.2]
  def change
    add_column :scenarios, :codelab, :string
  end
end
