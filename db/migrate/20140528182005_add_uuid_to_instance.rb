class AddUuidToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :uuid, :string
  end
end
