desc "Migrate instance bash_history and exit_status files into database"
task :migrate_instance_files => [:environment] do
  Instance.all.find_each do |instance|
    scenario = instance.scenario
    instance_directory = Rails.root.join(
      'data',
      Rails.env,
      scenario.user.id.to_s,
      "#{scenario.created_at.strftime("%y_%m_%d")}_#{scenario.name}_#{scenario.id}",
      'instances',
      instance.id.to_s
    )
    bash_history_path = instance_directory + 'bash_histories'
    exit_status_path = instance_directory + 'exit_statuses'
    if bash_history_path.exist? then
      content = bash_history_path.read.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      BashHistoryFile.import_bash_history_for_instance(instance, content)
    else
      Rails.logger.warn("Path '#{bash_history_path}' does not exit.")
    end

    if exit_status_path.exist? then
      content = exit_status_path.read.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      BashHistoryFile.import_exit_status_for_instance(instance, content)
    else
      Rails.logger.warn("Path '#{bash_history_path}' does not exit.")
    end
  end
end


