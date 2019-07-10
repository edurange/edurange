class AddComPageToScenarios < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :com_page, :string
  end
end
