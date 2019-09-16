class Instance < ActiveRecord::Base
  belongs_to :scenario
  has_many :instance_groups, dependent: :destroy
  has_many :groups, through: :instance_groups, dependent: :destroy
  has_many :players, through: :groups
  has_many :bash_histories, dependent: :delete_all
  has_one :user, through: :scenario
  validates :name, presence: true, uniqueness: { scope: :scenario, message: "Name taken" }

  attribute :ip_address_private, :string
  attribute :ip_address_public,  :string

  validate def validate_ip_addresses
    unless ip_address_private.nil? | IPAddress.valid_ipv4?(ip_address_private)
      errors.add(:ip_address_private, "not a valid IP address")
    end
    unless ip_address_public.nil? | IPAddress.valid_ipv4?(ip_address_public)
      errors.add(:ip_address_public, "not a valid IP address")
    end
  end

  def owner?(id)
    return self.subnet.cloud.scenario.user_id == id
  end

end
