class RemoveAwsPrefixesNameFromScenarios < ActiveRecord::Migration
  def change
    remove_column :scenarios, :aws_prefixes, :text
  end
end
