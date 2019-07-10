class RemoveInstanceS3Urls < ActiveRecord::Migration[4.2]
  def change
    columns = [:cookbook_url, :com_page, :bash_history_page, :exit_status_page, :script_log_page]
    columns.each do |column|
      remove_column :instances, column
    end
  end
end
