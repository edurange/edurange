class AddIpVisibleToInstanceGroup < ActiveRecord::Migration[4.2]
  def change
    add_column :instance_groups, :ip_visible, :boolean, default: true
  end
end
