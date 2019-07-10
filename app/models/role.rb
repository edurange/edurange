class Role < ActiveRecord::Base
  belongs_to :scenario
  has_many :role_recipes, dependent: :destroy
  has_many :recipes, through: :role_recipes
  has_many :instance_roles, dependent: :destroy
  has_many :instances, through: :instance_roles
  has_one :user, through: :scenario

  serialize :packages, Array

  validates :name, presence: true, uniqueness: { scope: :scenario }
  validates :scenario, presence: true
  validate :instances_stopped

  before_destroy :instances_stopped?, prepend: :true
  after_destroy :update_scenario_modified

  def instances_stopped
    unless instances_stopped?
      errors.add(:running, "the following instances using this role must be stopped"\
                           "before deletion or modification of role. #{instances.to_s}")
    end
  end

  def instances_stopped?
    instances.all? { |instance| instance.stopped? }
  end

  def update_scenario_modified
    scenario.update_attribute(:modified, true) if scenario.modifiable?
  end

  def package_add(name)
    if name.class != String or name == ''
      errors.add(:packages, 'package must be non blank String')
    elsif self.packages.include? name
      errors.add(:packages, "package already exists")
    else
      update(packages: packages << name )
    end

    return errors.empty?
  end

  def package_remove(name)
    if not self.packages.include? name
      errors.add(:packages, "package does not exist")
    else
      # I swear this works: try `["one", "two", "three"] - ["two"]` in a ruby console
      # (it outputs `["one", "three"]`
      update(packages: packages - [name])
    end
    return errors.empty?
  end
end
