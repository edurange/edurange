class AddPublicIpAddressToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :ip_address_public, :string
  end
end
