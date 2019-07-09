class Answer < ActiveRecord::Base
  belongs_to :user
  belongs_to :question

  validate :validate_text
  validate :validate_comment
  validate :validate_essay_points_earned

  # ensure that text is not blank in an answer
  def validate_text
    if self.question.type_of == "Essay" and self.text_essay == "" #problem here, question isn't linking correctly to answer. do a SQL query...
      errors.add(:text_essay, 'must not be blank')
      return false
    else
      if self.text == ""
  	errors.add(:text, 'must not be blank')
  	return false
      end
    end
    true
  end

  # if comment is nil return true else return true if comment is not blank
  def validate_comment
    return true if self.comment == nil
    self.comment = self.comment.strip
    if self.comment == ""
      errors.add(:comment, 'must not be blank')
      return false
    end
    true
  end

  # return true if essay points earned is nil else ensure that points earned is an integer type greater than 0 and question points
  def validate_essay_points_earned
    return true if self.essay_points_earned == nil
    self.essay_points_earned = self.essay_points_earned.strip
    if self.essay_points_earned == ""
      errors.add(:essay_points_earned, 'must not be blank')
      return false
    end
    if not self.essay_points_earned.is_integer? 
      errors.add(:essay_points_earned, 'must be zero or a positive integer')
      return false
    end
    if (self.essay_points_earned.to_i < 0) or (self.essay_points_earned.to_i > self.question.points)
      errors.add(:essay_points_earned, "must be between 0 and #{self.question.points}")
      return false
    end
    true
  end
end
