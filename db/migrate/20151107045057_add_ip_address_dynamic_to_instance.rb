class AddIpAddressDynamicToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :ip_address_dynamic, :string, default: nil
  end
end
