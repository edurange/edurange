class AddExitStatusPageToInstance < ActiveRecord::Migration[4.2]
  def change
    add_column :instances, :exit_status_page, :string
  end
end
