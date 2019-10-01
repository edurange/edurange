class Variable < ActiveRecord::Base
  validates  :value, presence: true
  belongs_to :variable_template, required: true

  # NOTE: a variable can belong EITHER a player or a scenario but NOT BOTH.
  belongs_to :player
  belongs_to :scenario

  delegate :name, :type, :password?, :random?, :string?, :openssl_pkey_rsa?, to: :variable_template

  def self.find_by_name name
    joins(:variable_template).find_by(variable_templates: { name: name })
  end

end
