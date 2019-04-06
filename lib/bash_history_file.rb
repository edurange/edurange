
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
end

