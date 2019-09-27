class Question < ActiveRecord::Base
  belongs_to :scenario
  has_many :answers, dependent: :destroy
  serialize :options
  serialize :values

  validates :text, presence: true, uniqueness: { scope: :scenario, message: "must be unique." }
  validates :type_of, presence: true

  # validate :validate_text
  validate :validate_options
  validate :validate_values

  after_create :set_order

  TYPES = ["String", "Number", "Essay"]
  # TYPES = ["String", "Number", "Essay", "Event"]
  OPTIONS_STRING = ["ignore-case", "variable-group-player"]
  OPTIONS_NUMBER = ["accept-integer", "accept-decimal", "accept-hex"]
  OPTIONS_ESSAY = ["larger-text-field"]

  def validate_options
    # check for valid type
    if not Question::TYPES.include? self.type_of
      errors.add(:type_of, 'not a valid type')
      return false
    end

    # check string type
    if self.type_of == "String" && self.options != nil
      # check for valid options
      if self.options.select{ |opt| OPTIONS_STRING.include? opt }.size != self.options.size
        errors.add(:options, 'invalid option')
        return
      end
    elsif self.type_of == "Number"
      # number type must have at least one option
      if self.options.size == 0
        errors.add(:options, 'must have at least one option')
        return false
      end

      # check for valid options
      if self.options.select{ |opt| OPTIONS_NUMBER.include? opt }.size != self.options.size
        errors.add(:options, 'invalid option')
        return
      end
    elsif self.type_of == "Essay"
      # check for valid options
      if self.options.select{ |opt| OPTIONS_ESSAY.include? opt }.size != self.options.size
        errors.add(:options, 'invalid option')
        return
      end
    end
  end

  def validate_values

    # check Essay type
    if self.type_of == "Essay"
      if not self.points
        errors.add(:points, 'must not be blank')
        return false
      end
      if not (self.points.to_s.is_integer? and self.points >= 0)
        errors.add(:points, 'must be zero or a positive integer')
        return false
      end
      return true
    end

    # check for no value or blank values
    if not self.values
      errors.add(:values, 'need at least one value')
      return false
    end
    if self.values.size < 1
      errors.add(:values, 'need at least one value')
      return false
    end

    # check for correct fields in value and add up points
    valuearr = []
    points_total = 0
    self.values.each do |value|

      # check that value is a hash
      if value.class != Hash
        errors.add(:values, "value field is not hash")
        return false
      end

      # check for missing fields
      err = false
      if not value[:value]
        errors.add(:values, "value field in hash missing")
        err = true
      end
      if not value[:points]
        errors.add(:values, "points field in hash missing")
        err = true
      end
      return false if err

      # check for extra fields in hash
      if not (value.size == 2 or value.size == 3)
        errors.add(:values, "missing or extra fields in value hash #{values}")
        return false
      end

      # remove value leading and trailing whitespace
      value[:value] = value[:value].strip

      # check for special
      if match_data = /\$.+\$/.match(value[:value])
        name = match_data.to_s.gsub("$", "")
        puts self.scenario.instances.size
        if instance = self.scenario.instances.select { |i| i.name == name }.first
          value[:special] = value[:value]
          value[:value] = value[:special].gsub(match_data.to_s, instance.ip_address)
        end
      end

      # check that points are integers
      if not value[:points].to_i > 0 and value[:points].is_integer?
        errors.add(:values, "points is not zero or positive integer")
        err = true
      end
      return false if err

      # add points to total
      points_total += value[:points].to_i

      # check for duplicate values keep track of values in valuearr
      if self.type_of == "String"
        if valuearr.include? value[:value]
          errors.add(:values, "duplicate values not allowed")
          return false
        end
      elsif self.type_of == "Number"
        valuearr.each do |v|
          if Float(v) == Float(value[:value])
            errors.add(:values, "duplicate values not allowed")
            return false
          end
        end
      end
      valuearr << value[:value]
    end

    # set points
    self.points = points_total

    # if type is NUmber check that each value is accepted by options
    if not self.type_of == "Number"
      return true
    end
    self.values.each do |value|
      accepted = false
      if self.options.include? "accept-integer"
        accepted = true if value[:value].is_integer?
      end
      if self.options.include? "accept-decimal"
        accepted = true if value[:value].is_decimal?
      end
      if self.options.include? "accept-hex"
        accepted = true if value[:value].is_hex?
      end
      if not accepted
        errors.add(:values, "value '#{value[:value]}' is not in an accepted format see options")
        return false
      end
    end

    true
  end

  def set_order #what do we do for 0 questions?
    if not self.order
      if self.scenario.questions.size == 1
        self.update_attribute(:order, 1)
      else
        self.update_attribute(:order, self.scenario.questions.maximum("order") + 1)
      end
    end
  end

  def move_up
    if above = self.scenario.questions.find_by_order(self.order + 1)
      above.update_attribute(:order, self.order)
      self.update_attribute(:order, self.order + 1)
    else
      return self
    end
    above.save
    return above
  end

  def move_down
    if below = self.scenario.questions.find_by_order(self.order - 1)
      below_order = below.order
      below.update_attribute(:order, self.order)
      self.update_attribute(:order, below_order)
    else
      return self
    end
    below.save
    return below
  end

  def answer_string(text, user_id)

    player = scenario.players.find_by(user_id: user_id)

    text = text.strip

    correct = false
    index = nil

    answer = self.answers.new(user_id: user_id, text: text)

    if self.type_of != "String"
      answer.errors.add(:type_of, 'must be type String')
      return answer
    elsif text == ""
      answer.errors.add(:text, 'can not be blank')
      return answer
    end

    self.values.each_with_index do |value, i|

      if self.options.include? "variable-group-player"
        group_name, var_name = value[:value].split(':')
        variable = player.variables.find_by_name(var_name)
        logger.debug("WATWATWAT #{variable.value}")
        value[:value] = variable.value
      end

      if self.options.include? "ignore-case"
        self.answers.where("user_id = ?", user_id).each do |answer|
          if answer.text.casecmp(text) == 0
            answer.errors.add(:duplicate, "duplicate answer")
            return answer
          end
        end

        correct = true if value[:value].casecmp(text) == 0
      else
        self.answers.where("user_id = ?", user_id).each do |answer|
          if answer.text == text
            answer.errors.add(:duplicate, "duplicate answer")
            return answer
          end
        end

        correct = true if value[:value] == text
      end

      if correct
        index = i
        break
      end

    end

    answer.correct = correct
    answer.value_index = index
    answer.save
    answer
  end

  def answer_number(text, user_id)
    text = text.strip

    answer = Answer.new(user_id: user_id, text: text)

    if not self.type_of == "Number"
      answer.errors.add(:type_of, "must be type Number")
      return answer
    end

    if text == ""
      answer.errors.add(:text, 'can not be blank')
      return answer
    end

    # check that answer is in an accepted format
    accepted = false
    self.options.each do |option|
      if option == "accept-integer"
        accepted = true if text.is_integer?
      elsif option == "accept-decimal"
        accepted = true if text.is_decimal?
      elsif option == "accept-hex"
        accepted = true if text.is_hex?
      end
    end

    if not accepted
      errmsg = 'must be '
      self.options.each_with_index do |option, i|
        errmsg += 'integer' if option == 'accept-integer'
        errmsg += 'decimal' if option == 'accept-decimal'
        errmsg += 'hex' if option == 'accept-hex'
        if i < self.options.size - 1
          errmsg += ' or '
        end
      end
      answer.errors.add(:options, errmsg)
      return answer
    end

    # go through each value looking for answer
    correct = false
    index = nil
    self.values.each_with_index do |value, i|

      # check for duplicate values
      if self.answers.where("user_id = ?", user_id).select { |a| Float(text) == Float(a.text) }.size > 0
        answer.errors.add(:duplicate, "duplicate answer")
        return answer
      end

      # check answer
      if Float(text) == Float(value[:value])
        correct = true
      end

      # break if answer is correct and set index
      if correct
        index = i
        break
      end

    end

    answer.question_id = self.id
    answer.correct = correct
    answer.value_index = index
    answer.save
    answer
  end

  def answer_essay(text, user_id)
    text = text.strip

    answer = Answer.new(user_id: user_id, text_essay: text)

    if not self.type_of == "Essay"
      answer.errors.add(:type_of, "must be type Number")
      return answer
    end
    answer.question_id = self.id
    answer.save
    answer
  end

  def student_answers(user_id)
    self.answers.where("user_id = ?", user_id)
  end

end
