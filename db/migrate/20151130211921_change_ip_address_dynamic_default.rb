class ChangeIpAddressDynamicDefault < ActiveRecord::Migration[4.2]
  def up
    change_column_default :instances, :ip_address_dynamic, ""
  end

  def down
  	change_column_default :instances, :ip_address_dynamic, nil
  end
end
