class AddComPageToInstances < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :com_page, :string
  end
end
