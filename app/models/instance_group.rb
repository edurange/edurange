class InstanceGroup < ActiveRecord::Base
  belongs_to :group
  belongs_to :instance
  has_one :user, through: :instance
  has_one :scenario, through: :group

  validate :validate
  validates :instance, presence: true
  validates :group, presence: true

  def validate
    if InstanceGroup.where("group_id = ? AND instance_id = ? AND administrator = ?", self.group_id, self.instance_id, self.administrator).size > 0
      errors.add(:name, "Already exists")
      return false
    end
    true
  end

end
