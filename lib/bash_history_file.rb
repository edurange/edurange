require 'ostruct'
require 'strscan'

module BashHistoryFile
  def self.parse contents
    hash = {} # {user -> { timestamp -> command }}
    user = nil
    time = nil

    contents.split("\n").each do |line|
      if /^\#\#\#\s/.match(line) # ignore timestamp
      elsif /^\#\#\s/.match(line)
        user = line[3..-1]
        hash[user] = {} if not hash.has_key?(user)
        time = nil
      else
        if /^#\d{10}$/.match(line)
          time = line[1..-1]
        else
          hash[user][time] = line if (user and time and not /^\s*$/.match(line))
        end
      end
    end
    hash
  end

  def self.parse_exit_statuses input
    input = StringScanner.new(input)
    commands = []

    return commands if input.eos?

    # ignore first line, which is a timestamp
    input.scan_until(/\n/)

    while input.check(/##/)
      input.scan(/## /)
      player_login = input.scan_until(/\n/).strip

      # if there are no commands for this user skip to the next one.
      next if input.check(/##/) or input.eos?

      # first two lines are junk
      input.scan_until(/\n/)
      input.scan_until(/\n/)

      while not input.check(/##/) and not input.eos?
        if input.check(/\n/) then
          input.scan(/\n/)
          next
        end
        exit_status = input.scan(/\d+/).to_i
        input.scan(/\n/)
        index = input.scan(/\d+ /)
        time = input.scan(/\d\d:\d\d:\d\d/)
        input.scan(/ /)
        command = input.scan_until(/\n/)
        if exit_status.present? and index.present? and time.present? and command.present? then
          commands << OpenStruct.new(
            player_login: player_login,
            exit_status: exit_status,
            time: time,
            command: command.strip
          )
        else
          #puts "idk wth happened: #{index}|#{time}|#{command}"
        end
      end
      input.scan(/\n/)
    end
    commands
  end

  def self.import_bash_history_for_instance instance, contents
    BashHistoryFile.parse(contents).each do |user_name, commands|
      player = instance.players.find_by(login: user_name)
      if player then
        commands.each do |timestamp, command|
          BashHistory.find_or_create_by!(
            instance: instance,
            player: player,
            command: command,
            performed_at: Time.at(timestamp.to_i).to_datetime
          )
        end
      end
    end
  end

  def self.import_exit_status_for_instance instance, contents
    # download exit_statuses and correlate them with the command
    BashHistoryFile.parse_exit_statuses(contents).each do |record|
      player = instance.players.find_by(login: record.player_login)
      if player then
        BashHistory
          .where("performed_at::time = :time", time: record.time)
          .where(instance: instance, player: player)
          .update_all(exit_status: record.exit_status)
      end
    end
  end

end

