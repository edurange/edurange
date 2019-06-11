class Variable < ActiveRecord::Base
  validates  :value, presence: true
  belongs_to :variable_template, required: true

  def name
    variable_template.name
  end

  def type
    variable_template.type
  end

end
