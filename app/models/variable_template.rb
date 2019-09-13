class VariableTemplate < ActiveRecord::Base
  self.inheritance_column = nil # otherwise rails would be confused by the 'type' column.

  # both groups and scenarios can have many variable templates
  belongs_to :group
  belongs_to :scenario
  # a variable template has many instatiations as variables
  has_many   :variables

  validates :name, presence: true, uniqueness: {scope: [:group_id, :scenario_id], allow_blank: false}
  validates :type, presence: true
  validates :value, presence: true, if: :string?

  enum type: {
    random: 'random',
    openssl_pkey_rsa: 'openssl_pkey_rsa',
    string: 'string',
    password: 'password'
  }

  after_create :instantiate_for

  def generate_value
    case
      when random? || password?
        SecureRandom.hex(4)
      when openssl_pkey_rsa?
        OpenSSL::PKey::RSA.new(2048).to_pem
      else
        value
    end
  end

  def instantiate
    Variable.new(
      variable_template: self,
      value: generate_value
    )
  end

  def instantiate_for
    entity = group || scenario
    entity.instantiate_variable self
  end

  def scenario
    super || group.scenario
  end

end
