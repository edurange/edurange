class Variable < ActiveRecord::Base
  validates  :value, presence: true
  belongs_to :variable_template, required: true
  belongs_to :player
  belongs_to :scenario

  def name
    variable_template.name
  end

  def type
    variable_template.type
  end

  def password?
    variable_template.password?
  end

  def self.find_by_name name
    joins(:variable_template).find_by(variable_templates: { name: name })
  end

end
