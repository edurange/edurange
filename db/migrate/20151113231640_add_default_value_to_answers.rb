class AddDefaultValueToAnswers < ActiveRecord::Migration[4.2]
  def up
  	change_column :scenarios, :answers, :string, default: ""
  end

  def down
  	change_column :scenarios, :answers, :string, default: nil
  end
end
