class RemoveAwsPrefixesNameFromScenarios < ActiveRecord::Migration[4.2]
  def change
    remove_column :scenarios, :aws_prefixes, :text
  end
end
