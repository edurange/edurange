class InstanceGroup < ActiveRecord::Base
  belongs_to :group
  belongs_to :instance
  has_one :user, through: :instance
  has_one :scenario, through: :group

  validate :validate
  validates :instance, presence: true
  validates :group, presence: true

  after_save :update_scenario_modified
  after_destroy :update_scenario_modified

  def update_scenario_modified
    if self.scenario.modifiable?
      return self.instance.scenario.update_attribute(:modified, true)
    end
    false
  end

  def validate
    if not self.instance.stopped?
      errors.add(:name, "instance must be stopped first")
      return false
    end

    if self.instance.os == "nat" and self.administrator == true
      errors.add(:access, "can not have admin access on NAT instances")
      return false
    end

    if ig = InstanceGroup.where("group_id = ? AND instance_id = ?", self.group_id, self.instance_id).first
      errors.add(:name, "already has #{ig.administrator == true ? 'admin' : 'user'} accesss")
      return false
    end

    if InstanceGroup.where("group_id = ? AND instance_id = ? AND administrator = ?", self.group_id, self.instance_id, self.administrator).size > 0
      errors.add(:name, "Already exists")
      return false
    end
    true
  end

end
