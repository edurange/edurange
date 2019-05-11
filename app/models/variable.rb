class Variable < ActiveRecord::Base
  self.inheritance_column = nil # otherwise rails would be confused by the 'type' column.

  validates :name, presence: true
  validates :type, presence: true
  validates :value, presence: true, if: :string?

  enum type: {
    random: 'random',
    openssl_pkey_rsa: 'openssl_pkey_rsa',
    string: 'string'
  }

  after_initialize def instantiate!
    self.value = case
      when random?
        SecureRandom.hex(4)
      when openssl_pkey_rsa?
        OpenSSL::PKey::RSA.new(2048).to_pem
      else
        value
    end
  end

end
