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
      next if input.check(/##/)

      # first two lines are junk
      input.scan_until(/\n/)
      input.scan_until(/\n/)

      while not (input.check(/##/) or input.eos? or input.check(/\n/))
        exit_status = input.scan(/\d+/).to_i
        input.scan(/\n/)
        input.scan(/\d /)
        time = input.scan(/\d\d:\d\d:\d\d/)
        input.scan(/ /)
        command = input.scan_until(/\n/).strip
        commands << OpenStruct.new(
          player_login: player_login,
          exit_status: exit_status,
          time: time,
          command: command
        )
      end
    end
    commands
  end

end

