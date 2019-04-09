class Subnet < ActiveRecord::Base
  include Provider

  belongs_to :cloud
  has_many :instances, dependent: :destroy
  has_one :user, through: :cloud

  validates :name, presence: true, uniqueness: { scope: :cloud, message: "name already taken" }
  validates_presence_of :cidr_block, :cloud
  validate :cidr_validate, :internet_validate, :validate_stopped

  after_destroy :update_scenario_modified
  before_destroy :validate_stopped, prepend: true

  def validate_stopped
    if not self.stopped?
      errors.add(:running, "can not modify while subnet is booted")
      return false
    end
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  def independent_destroy
    if self.instances.size > 0
      errors.add(:dependents, "must not have any instances")
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

  def internet_validate
    if not self.internet_accessible
      self.instances.each do |instance|
        if instance.internet_accessible
          errors.add(:internet_accessible, "If subnet is not internet accessible then #{instance.name} should be the same")
        end
      end
    end
  end

  def cidr_validate
    return unless self.cidr_block

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

    # Check that CIDR is a subset of its cloud CIDRs
    cloud_cidr = NetAddr::CIDR.create(self.cloud.cidr_block)
    if not (cloud_cidr == self.cidr_block or cloud_cidr.contains? self.cidr_block)
      self.errors.add(:cidr_block, "Subnets CIDR block is not with its clouds CIDR block")
      return
    end

    # Check that CIDR contains all subnet
    self.cloud.subnets.select{ |s| s != self }.each do |subnet|
      if NetAddr::CIDR.create(self.cidr_block).cmp(subnet.cidr_block) != nil
        self.errors.add(:cidr_block, "CIDR block must not overlap with subnet #{subnet.name} #{subnet.cidr_block}")
        return
      end
    end

    # Check that all instances are within subnet
    self.instances.each do |instance|
      if NetAddr::CIDR.create(self.cidr_block).cmp(instance.ip_address) != 1
        self.errors.add(:cidr_block, "CIDR does not contain instance #{instance.name} #{instance.ip_address}")
      end
    end

    true
  end

  def add_progress(val)
    # debug "Adding progress to subnet"
    # PrivatePub.publish_to "/scenarios/#{self.cloud.scenario.id}", subnet_progress: val
  end

  def owner?(id)
    return self.cloud.scenario.user_id == id
  end

  def scenario
    return self.cloud.scenario
  end

end
