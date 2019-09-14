class Instance < ActiveRecord::Base
  require 'open-uri'
  require 'csv'

  belongs_to :scenario
  has_many :instance_groups, dependent: :destroy
  has_many :groups, through: :instance_groups, dependent: :destroy
  has_many :players, through: :groups
  has_many :bash_histories, dependent: :delete_all
  has_one :user, through: :scenario


  validates :name, presence: true, uniqueness: { scope: :scenario, message: "Name taken" }

  after_destroy :update_scenario_modified

  def update_scenario_modified
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  # Add a role to the scenario
  def role_add(role_name)
    if not self.stopped?
      errors.add(:running, 'instance must be stopped to add role')
      return false
    end

    self.roles.each do |r|
      if r.name == role_name
        self.errors.add(:role_name, "Instance already has #{role_name}")
        return false
      end
    end

    if not role = self.scenario.roles.find_by_name(role_name)
      self.errors.add(:role_name, "Role does not exist")
      return false
    end
    ir = self.instance_roles.new(role_id: role.id)
    ir.save
    update_scenario_modified
    return ir
  end

  def owner?(id)
    return self.subnet.cloud.scenario.user_id == id
  end

end
