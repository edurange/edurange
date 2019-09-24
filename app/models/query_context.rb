#
# This class provides a safe and simple way to query the state of a object for use in QuestionQueryTest
#
# For example we can imagine a scenario where an instance has a dynamically assigned private ip address.
# A question might be, "what is the ip address of the instance running the ftp server?"
# And the answer would be "${scenario/instances/ftp_server/ip_address_private}"
#
# This should be the only file that needs to be modified for edurange to support
# new dynamic values in questions.
#
# See test/models/question_query_test.rb for example of how and how not to use the class.

class QueryError < StandardError
end

class QueryContext
  include ActiveModel::Model
  attr_accessor :scenario, :player

  PATH_DELIMITER = '/' # People might be more comfortable with . (dot), for example ${player.login} vs ${player/login}

  def evaluate(text)
    matches = text.scan(/\$\{.+?\}/)
    matches.each do |match|
      path = match.delete_suffix('}').delete_prefix('${')
      val  = evaluate_path(path)
      text = text.gsub(match, val)
    end
    text
  end

  def evaluate_path(path)
    evaluate_parts(path.split(PATH_DELIMITER))
  end

  def evaluate_parts(parts)
    raise QueryError.new("can not be empty") unless parts.size > 0
    case parts.first
    when 'player'
      evaluate_player(parts.drop(1))
    when 'scenario'
      evaluate_scenario(parts.drop(1))
    else
      raise QueryError.new("expecting 'player' or 'scenario', got '#{parts.first}'")
    end
  end

  def evaluate_scenario(parts)
    raise QueryError.new("invalid path") unless parts.size > 0
    case parts.first
    when 'instances'
      evaluate_instances(parts.drop(1))
    when 'variables'
      evaluate_variable(scenario, parts.drop(1))
    else
      evaluate_attribute(scenario, parts)
    end
  end

  def evaluate_variable(entity, parts)
    raise QueryError.new("invalid path: expected attribute name, found '#{parts.join(PATH_DELIMITER)}'") unless parts.size == 1
    variable = entity.variables.find_by_name(parts.first)
    raise QueryError.new("invalid path: no variable with name #{parts.first}") if variable.nil?
    variable.value
  end


  def evaluate_instances(parts)
    raise QueryError.new("invalid path: expected instance name") unless parts.size > 0
    instance = scenario.instances.find_by_name(parts.first)
    raise QueryError.new("invalid path: no instance with name #{parts.first}") if instance.nil?
    evaluate_attribute(instance, parts.drop(1))
  end

  def evaluate_player(parts)
    raise QueryError.new("invalid path") unless parts.size > 0
    if parts.first == 'variables'
      evaluate_variable(player, parts.drop(1))
    else
      evaluate_attribute(player, parts)
    end
  end

  def evaluate_attribute(entity, parts)
    raise QueryError.new("invalid path: expected attribute name") unless parts.size == 1
    val = entity.read_attribute(parts.first)
    raise QueryError.new("invalid path: no attribute with name #{parts.first}") if val.nil?
    val
  end

end
