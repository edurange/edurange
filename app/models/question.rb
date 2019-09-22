class Question < ActiveRecord::Base
  belongs_to :scenario
  has_many :answers, dependent: :destroy
  serialize :options
  serialize :values

  validates :text, presence: true, uniqueness: { scope: :scenario, message: "must be unique." }
  validates :type_of, presence: true
  validates :order, presence: true

  # validate :validate_text
  validate :validate_options
  validate :validate_values

  def string?
    type_of == "String"
  end

  def number?
    type_of == "Number"
  end

  def essay?
    type_of == "Essay"
  end

  def accept_integer?
    self.number? & (self.options.include? 'accept-integer')
  end

  def accept_decimal?
    self.number? & (self.options.include? 'accept-decimal')
  end

  def accept_hex?
    self.number? & (self.options.include? 'accept-hex')
  end

  TYPES = ["String", "Number", "Essay"]
  # TYPES = ["String", "Number", "Essay", "Event"]
  OPTIONS_STRING = ["ignore-case", "variable-group-player"]
  OPTIONS_NUMBER = ["accept-integer", "accept-decimal", "accept-hex"]
  OPTIONS_ESSAY = ["larger-text-field"]

  def ignore_case?
    self.options.include? "ignore-case"
  end

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

  def answer_essay(text, user_id)
    text = text.strip

    answer = Answer.new(question: self, user: User.find(user_id), text_essay: text)

    if not self.type_of == "Essay"
      answer.errors.add(:type_of, "must be type Number")
      return answer
    end
    answer.save
    answer
  end

  def student_answers(user_id)
    self.answers.where("user_id = ?", user_id)
  end

end
