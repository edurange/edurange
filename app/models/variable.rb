class Variable < ActiveRecord::Base
  self.inheritance_column = nil # otherwise rails would be confused by the 'type' column.

  # both players and groups can have many variables.
  belongs_to :group
  belongs_to :player

  def self.template
    where(template: true)
  end

  def self.not_template
    where(template: false)
  end

  validates :name, presence: true, uniqueness: {scope: [:group_id, :player_id], allow_blank: false}
  validates :type, presence: true
  validates :value, presence: true, if: :string?

  enum type: {
    random: 'random',
    openssl_pkey_rsa: 'openssl_pkey_rsa',
    string: 'string'
  }

  def generate_value
    case
      when random?
        SecureRandom.hex(4)
      when openssl_pkey_rsa?
        OpenSSL::PKey::RSA.new(2048).to_pem
      else
        value
    end
  end

  def instantiate
    Variable.new(
      name: name,
      type: type,
      value: generate_value,
      template: false
    )
  end

end
