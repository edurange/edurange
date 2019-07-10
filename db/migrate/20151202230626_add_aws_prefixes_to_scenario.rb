class AddAwsPrefixesToScenario < ActiveRecord::Migration[4.2]
  def change
    add_column :scenarios, :aws_prefixes, :string
  end
end
