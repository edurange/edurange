class InstanceGroup < ActiveRecord::Base
  belongs_to :group
  belongs_to :instance

  has_one :user,     through: :instance
  has_one :scenario, through: :group

  validates :instance, presence: true
  validates :group, presence: true

  validate def validate
    if InstanceGroup.where(group_id: self.group_id, instance_id: self.instance_id, administrator: self.administrator).size > 0
      errors.add(:name, "Already exists")
      return false
    end
    true
  end

end
