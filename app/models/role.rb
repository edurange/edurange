class Role < ActiveRecord::Base
  belongs_to :scenario
  has_many :role_recipes, dependent: :destroy
  has_many :recipes, through: :role_recipes
  has_many :instance_roles, dependent: :destroy
  has_one :user, through: :scenario

  serialize :packages, Array

  validates :name, presence: true, uniqueness: { scope: :scenario, message: "Name taken" }
  validate :instances_stopped

  before_destroy :instances_stopped, prepend: :true
  after_destroy :update_scenario_modified

  def instances_stopped
    self.instance_roles.each do |instance_role|
      instances = []
      if not instance_role.instance.stopped?
        instances << instance_role.instance.name
      end
      if instances.size > 0
        errors.add(:running, "the following instances using this role must be stopped before deletion or modification of role. #{instances.to_s}")
        return false
      end
    end
    if self.scenario.modifiable?
      self.scenario.update(modified: true)
    end
    true
  end

  def instances_stopped?
    self.instance_roles.each do |instance_role|
      if not instance_role.instance.stopped?
        return false
      end
    end
    true
  end

  def update_scenario_modified
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  def package_add(name)
    if name.class != String or name == ''
      errors.add(:packages, 'package must be non blank String')
      return false
    end
    if self.packages.include? name
      errors.add(:packages, "package already exists")
      return false
    else
      self.update(packages: packages << name )
      if self.errors.any?
        return false
      end
    end
    true
  end

  def package_remove(name)
    if not self.packages.include? name
      errors.add(:packages, "package does not exist")
      return false
    else
      packages = self.packages
      packages.delete(name)
      self.update(packages: packages)
      if self.errors.any?
        return false
      end
    end
    true
  end

end
