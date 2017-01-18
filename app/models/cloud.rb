# This file has a few validations, described below. It maintains state and
# attributes corresponding to an AWS Virtual Private Cloud object.

class Cloud < ActiveRecord::Base
  include Provider

  belongs_to :scenario
  has_many :subnets, dependent: :destroy
  has_one :user, through: :scenario

  # validations
  validates :name, presence: true, uniqueness: { scope: :scenario, message: "name already taken" } 

  validates_presence_of :cidr_block, :scenario
  validate :cidr_validate, :validate_stopped

  after_destroy :update_scenario_modified
  before_destroy :validate_stopped, prepend: true

  def validate_stopped
    if not self.stopped?
      errors.add(:running, "can not modify while scenario is not stopped")
      return false
    end
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  def independent_destroy
    if self.subnets.size > 0
      errors.add(:dependents, "must not have any subnets")
      return false
    end
    self.destroy
    true
  end

  def update_scenario_modified
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  def owner?(id)
    return self.scenario.user_id == id
  end

  def ip_taken?(ip)
    return self.subnets.select{ |subnet| subnet.instances.select{ |instance| instance.ip_address == ip }.size > 0 }.size > 0
  end

  def subnets_booting?
    return self.subnets.select{ |s| (s.booting? or s.queued_boot?) }.any?
  end

  def subnets_unbooting?
    return self.subnets.select{ |s| s.unbooting? or s.queued_unboot? }.any?
  end

  def subnets_boot_failed?
    return self.subnets.select{ |s| s.boot_failed? }.any?
  end

  def subnets_unboot_failed?
    return self.subnets.select{ |s| s.unboot_failed? }.any?
  end

  def subnets_booted?
    return self.subnets.select{ |s| s.booted? }.any?
  end

  def subnets_stopped?
    self.subnets.select{ |s| not s.stopped? }.size == 0
  end

  def cidr_validate

    # Check for valid CIDR
    if IPAddress.valid_ipv4?(self.cidr_block.split('/')[0])
      mask = self.cidr_block.split('/')[1]
      if not mask
        errors.add(:cidr_block, "Need a subnet mask")
        return
      elsif not /^\d*\d$/.match(mask)
        errors.add(:cidr_block, "Subnet mask is invalid!")
        return
      elsif not (mask.to_i >= 16 and mask.to_i <= 28)
        errors.add(:cidr_block, "Subnet mask must be between #{16} - #{28}")
        return
      end
    else
      # Not an IP at all? Generic error! Whoo!
      errors.add(:cidr_block, "IP section is invalid!")
      return
    end

    # Check that each subnet of cloud is within cloud CIDR
    self.subnets.each do |subnet|
      ord = NetAddr::CIDR.create(self.cidr_block).cmp(subnet.cidr_block)
      puts subnet.cidr_block + " " + ord.to_s
      if ord != 1 and ord != 0
        self.errors.add(:cidr_block, "CIDR block does not encompass #{subnet.name}")
        return
      end
    end

  end

end
