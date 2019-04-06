class Statistic < ActiveRecord::Base
  belongs_to :user
  belongs_to :scenario

  # active directory has support for arrays and hash tables
  serialize :bash_analytics
  serialize :resource_info

  after_create :create
  before_destroy :check_scenario

  def check_scenario
    if self.scenario
      errors.add(:destroy, 'can not destroy if scenario exists')
      return false
    end
    true
  end

  def create
    self.scenario_id = self.scenario.id
    self.user_id = self.scenario.user_id
    self.scenario_name = self.scenario.name
    self.scenario_created_at = self.scenario.created_at
    gen_info
    self.save
  end

  def gen_info
    return if not self.scenario
    info = {
      instances: {},
      scenario: {
        id: self.scenario.id,
        name: self.scenario.name,
      }
    }
    self.scenario.instances.each do |i|
      info[:instances][i.name] = {id: i.id, users: i.player_names }
    end
    self.update_attribute(:resource_info, info)
  end

  def gen_instance_files
    self.resource_info[:instances].each do |name, info|
      bash_histories_path = self.data_instance_bash_histories_path(name)
      exit_statuses_path = self.data_instance_exit_statuses_path(name)
      script_logs_path = self.data_instance_script_logs_path(name)
      FileUtils.touch(bash_histories_path) if not File.exists? 
      FileUtils.touch(exit_statuses_path) if not File.exists? 
      FileUtils.touch(script_logs_path) if not File.exists? 
    end
  end

  ## utility methods
  def unix_to_dt(ts)
    # convert unix timestamp to datetime object
    return DateTime.strptime(ts, format="%s")
  end

  def dates_in_window(start_time, end_time, timestamps)
    # input -> start_time, end_time: datetime objects defining
    #                                a window of time
    #          timestamps: a hash from corresponding to a specific user
    #             of the form {timestamp -> command}
    # output -> dates: a list of timestamps within a window of time
    window = timestamps.keys.select{ |d| unix_to_dt(d) >= start_time \
                                        && unix_to_dt(d) <= end_time }
    return window
  end

  def is_numeric?(s)  # check if a string is numeric or not
    # input -> s: a string
    # output -> true if the string is a number value, false otherwise
    begin
      if Float(s)
        return true
      end
    rescue
      return false
    end
  end

  def scenario_exists?
    return Scenario.find_by_id(self.scenario.id)
  end

  ## end utility methods

  # private
    # The methods below should not be private methods, as they will be
    # called from outside of this file. Namely, it will be taken care of
    # by the controller, with input coming from the statistics UI template.   
    # Statistic creation initially goes through a pipeline of operations
    # which successively cleans the unstructured data and organizes it
    # in such a way that analytics can be made possible.
    # Currently Statistic creation is done during the destruction of a Scenario,
    # whereby the bash data is brought down from an s3 bucket and
    # parsed into a nested Hash, mapping users to timestamps to commands.
    # The methods defined below are helper methods that allow the
    # investigator to reveal certain aspects of the data.
  def perform_analytics(data)
    # input -> data: a hash of the form { users -> list of strings of commands }
    # output -> results: a nested array of two-element arrays
    results = []  # [[ string, count ]] or {string => count},  chartkick can deal with either.
    frequencies = Hash.new(0)
    data.keys.each do | user |
      data[user].each do | cmd |
        if !frequencies.include?(cmd)
          frequencies[cmd] = 1
        else
          frequencies[cmd] += 1
        end
      end
    end
    return frequencies  
  end

  def grab_relevant_commands(users, start_time, end_time)
    # input -> users: a list of username strings
    #          start_time, end_time: strings which represent dates
    #                                that define a window of time
    # output -> a dictionary mapping users to a list of
    #           commands they've entered during a window of time

    result = Hash.new(0)  # {user -> relevant-commmands}
    start_time = unix_to_dt(start_time)
    end_time = unix_to_dt(end_time)
    bash_data = self.bash_analytics  # yank the data from model
    if users  # single user
      u = users  # grab that user and,
      timestamps = bash_data[u]  # create {timestamps -> command} from {user -> {timestamps -> command}}
      # grab list of timestamps within specified window of time
      window = dates_in_window(start_time, end_time, timestamps)         
      cmds = []  # to be array of commands within window
      window.each do |d|
        cmds << timestamps[d]
      end
      result[u] = cmds  # {user -> array of relevant commands}
      return result
    # elsif users.length > 1  # many users
   #    users.each do |u| # same as above but for each user
   #      cmds = []
   #      timestamps = bash_data[u]
   #      window = dates_in_window(start_time, end_time, timestamps)
   #      window.each do |d|
   #          cmds << timestamps[d]
   #      end
   #      result[u] = cmds
   #    end
   #    return result # users that map to lists of strings of commands
    # # empty hash (no commands within timeframe?)
    else
      return result
    end
  end

  def command_frequency(instance_name, user)
    return false if not self.resource_info[:instances].has_key?(instance_name)
    path = data_instance_by_id_user_command_frequency(self.resource_info[:instances][instance_name][:id], user)
    return false if not File.exists? path
    c = {}
    yml = YAML.load_file(path)
    yml.each { |command, count| c[command] = count } if yml
    c
  end

  def bash_history_instance_user(instance_name, user_name)
    data_read(data_instance_user_bash_history_path(instance_name, user_name))
  end

  def instance_id_get(name)
    self.resource_info[:instances][name][:id]
  end

  def instance_names
    self.resource_info[:instances].keys
  end

  def instance_user_names(instance_name)
    self.resource_info[:instances].each { |k,v| return v[:users] if k == instance_name  }
    []
  end

  def save_bash_histories_exit_status_script_log

    bash_histories = ""
    script_log = ""
    exit_status = ""

    # populate statistic with bash histories
    self.scenario.instances.all.each do |instance|
      # concatenate all bash histories into one big string
      bash_histories += instance.get_bash_history.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
      #puts instance.get_bash_history  # for debugging

      # Concatenate all script logs
      # Will look messy
      script_log += instance.get_script_log.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
      #puts instance.get_script_log # for debugging

      # Concatenate all exit status logs
      exit_status += instance.get_exit_status.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
      #puts instance.get_exit_status # for debugging

    end

    # partition the big bash history string into a nested hash structure
    # mapping usernames to the commands they entered.
    bash_partition = partition_bash(bash_histories.split("\n"))

    # create statistic file for download
    bash_analytics = ""
    bash_partition.each do |analytic|
      bash_analytics = bash_analytics + "#{analytic}" + "\n"
    end

    FileUtils.mkdir_p(self.data_path) if not File.exists?(self.data_path)

    file_text = "Scenario #{self.scenario_name} created at #{self.scenario_created_at}\nStatistic #{self.id} created at #{self.created_at}\n\nBash Histories: \n \n#{bash_histories} \n"
    File.open(self.data_path_statistic, "wb+") { |f| f.write(file_text) }

    #Create Script Log File

    #Referencing script log by script_log
    script_out = "Scenario #{self.scenario_name} created at #{self.scenario_created_at}\nStatistic #{self.id} created at #{self.created_at}\n\nScript Log: \n \n#{script_log} \n"
    File.open(self.data_path_script_log, "wb+") { |f| f.write(script_out) }

    #Create Exit Status file

    #Referencing exit status log by exit_status
    exit_stat_out = "Scenario #{self.scenario_name} created at #{self.scenario_created_at}\nStatistic #{self.id} created at #{self.created_at}\n\nExit Status Log: \n \n#{exit_status} \n"
    File.open(self.data_path_exit_status, "wb+") { |f| f.write(exit_stat_out) }
  end

  def save_questions_and_answers
    yml = { }
    questions = self.scenario.questions.map { |q|
      {
        "Id" => q.id,
        "Order" => q.order,
        "Text" => q.text,
        "Options" => q.options,
        "PointsPenalty" => q.points_penalty
      }
    }
    yml["Questions"] = questions

    students = []
    self.scenario.questions.each do |q|
      q.answers.each do |a|
        next if not a.user
        students.push({
          "Id" => a.user.id,
          "Name" => a.user.name,
          "Answers" => []
        }) if students.select{ |s| s["Id"] == a.user.id }.empty?
        student = students.select{ |s| s["Id"] == a.user.id }.first
        student["Answers"].push({
          "QuestionId" => q.id,
          "Text" => a.text,
          "TextEssay" => a.text_essay,
          "Comment" => a.comment,
          "ValueIndex" => a.value_index,
          "Correct" => a.correct,
          "EssayPoints" => a.essay_points_earned
        })
      end
    end
    yml["Students"] = students.map { |s| s }

    File.open(self.data_path_questions_answers, "w") { |f| f.write(yml.to_yaml) }
    yml.to_yaml
  end

  def save_scenario_yml
    File.open(self.data_path_scenario_yml, "w") do |f| 
      f.write(File.open(self.scenario.path_yml, 'r').read())
    end
  end

  def boot_log_last_read
    if path = Dir.glob("#{data_path_boot}/*").max_by { |f| File.mtime(f) }
      return File.open(path, 'r').read()
    end
    "Scenario has not been booted"
  end

  def data_read(path)
    File.open(path, 'r').read()
  end

  def data_all_name
    "EDURange-#{self.scenario_created_at.strftime("%y_%m_%d")}_#{self.scenario_name}_#{self.scenario_id}_statistics.zip"
  end
 
  def data_all_as_zip
    files = {}
    # go through each instance and user
    self.resource_info[:instances].each do |instance_name, values|
      values[:users].each do |user_name|
        path = data_instance_user_bash_history_path(instance_name, user_name)
        if File.exists? path
          files[data_instance_user_bash_history_download_name(instance_name, user_name)] = path
        end 
      end
      files[data_instance_exit_statuses_download_name(instance_name)] = data_instance_exit_statuses_path(instance_name)
      files[data_instance_script_logs_download_name(instance_name)] = data_instance_script_logs_path(instance_name)
    end

    # return files

    temp_file = Tempfile.new(self.data_all_name)
    begin
      Zip::OutputStream.open(temp_file.path) do |zos|
        files.each do |name, path|
          zos.put_next_entry(name)
          zos.print IO.read(path)
        end
      end
      #Initialize the temp file as a zip file
      # Zip::OutputStream.open(temp_file) { |zos| }

      # Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      #   file_paths.each do |path|
      #     zipfile.add(path, folder + path)
      #   end
      # end
      #Read the binary data from the file
      return File.read(temp_file.path)
    ensure
      #close and delete the temp file
      temp_file.close
      temp_file.unlink
    end
  end

  def data_instance_user_bash_history_path(instance_name, user_name)
    data_file_check "#{data_path_instance(instance_name)}/users/#{user_name}.bash_history.yml"
  end

  def data_instance_user_bash_history_download_name(instance_name, user_name)
    "EDURange-#{self.scenario_created_at.strftime("%y_%m_%d")}_#{self.scenario_name}_#{self.scenario_id}_#{instance_name}_#{user_name}_bash_history"
  end

  def data_instance_exit_statuses_path(instance_name)
    "#{data_path_instance(instance_name)}/exit_status"
  end

  def data_instance_exit_statuses_download_name(instance_name)
    "EDURange-#{self.scenario_created_at.strftime("%y_%m_%d")}_#{self.scenario_name}_#{self.scenario_id}_#{instance_name}_exit_statuses"
  end

  def data_instance_script_logs_path(instance_name)
    "#{data_path_instance(instance_name)}/script_log"
  end

  def data_instance_script_logs_download_name(instance_name)
    "EDURange-#{self.scenario_created_at.strftime("%y_%m_%d")}_#{self.scenario_name}_#{self.scenario_id}_#{instance_name}_script_logs"
  end

  def data_instance_bash_histories_path(instance_name)
    "#{data_path_instance(instance_name)}/bash_histories"
  end

  def data_instance_bash_histories_path_by_id(instance_id)
    "#{data_path_instance_by_id(instance_id)}/bash_histories"
  end

  def data_instance_exit_statuses_path(instance_name)
    "#{data_path_instance(instance_name)}/exit_statuses"
  end

  def data_instance_script_logs_path(instance_name)
    "#{data_path_instance(instance_name)}/script_logs"
  end

  def data_instance_by_id_user_bash_history_path(instance_id, user_name)
    data_file_check "#{data_path_instance_by_id_users(instance_id)}/#{user_name}.bash_history.yml"
  end

  def data_instance_by_name_user_command_frequency(instance_name, user_name)
    data_file_check "#{data_path_instance_users(instance_id)}/#{user_name}.command_frequency.yml"
  end

  def data_instance_by_id_user_command_frequency(instance_id, user_name)
    data_file_check "#{data_path_instance_by_id_users(instance_id)}/#{user_name}.command_frequency.yml"
  end

  def data_fetch_and_process
    data_fetch
    data_process
  end

  def data_fetch
    return if not scenario_exists?
    self.scenario.instances.each do |instance|
      instance.aws_instance_S3_files_save_no_log
    end
  end

  def data_process
    Dir.foreach(data_path_instances) do |instance_id|
      next if instance_id == '.' or instance_id == '..' or instance_id == 'users'

      bash_history = File.open(data_instance_bash_histories_path_by_id(instance_id), 'r').read().encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
      BashHistoryFile.parse(bash_history).each do |user_name, commands|

        File.open(data_instance_by_id_user_bash_history_path(instance_id, user_name), "w") do |f| 
          f.write(commands.to_yaml)
        end

        freq = {}
        commands.each { |k, v| freq.has_key?(v) ? freq[v] = (freq[v] + 1) : freq[v] = 1 }

        File.open(data_instance_by_id_user_command_frequency(instance_id, user_name), "w") do |f| 
          f.write(freq.to_yaml)
        end
      end
    end
  end

  def data_path_check(path)
    FileUtils.mkdir_p(path) if not File.exists?(path)
    path
  end

  def data_file_check(path)
    FileUtils.touch(path) if not File.exists?(path)
    path
  end

  def data_path
    data_path_check "#{Rails.root}/data/#{Rails.env}/#{self.user.id}/#{self.created_at.strftime("%y_%m_%d")}_#{self.resource_info[:scenario][:name]}_#{self.resource_info[:scenario][:id]}"
  end

  def data_path_boot
    data_path_check "#{self.data_path}/boot"
  end

  def data_path_questions_answers
    "#{self.data_path}/questions_and_answers.yml"
  end

  def data_path_scenario_yml
    "#{self.data_path}/#{self.scenario.name.downcase}.yml"
  end

  def data_path_instances
    data_path_check "#{self.data_path}/instances"
  end

  def data_path_instance(instance_name)
    data_path_check "#{self.data_path_instances}/#{self.resource_info[:instances][instance_name][:id]}"
  end

  def data_path_instance_by_id(instance_id)
    data_path_check "#{self.data_path_instances}/#{instance_id}"
  end

  def data_path_instance_by_id_users(instance_id)
    data_path_check "#{self.data_path_instance_by_id(instance_id)}/users"
  end

end
