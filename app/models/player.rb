require 'unix_crypt'
class Player < ActiveRecord::Base
  belongs_to :group
  validates_presence_of :group
  belongs_to :student_group
  belongs_to :user
  has_one :scenario, through: :group
  has_many :bash_histories, dependent: :delete_all
  has_many :variables, dependent: :destroy

  validates :login, presence: true, uniqueness: { scope: :group, message: "name already taken" }
  validates :password, presence: true
  validate :instances_stopped

  after_destroy :update_scenario_modified
  after_create :create_variables

  def update_scenario_modified
    if self.group.scenario.modifiable?
      if self.group.scenario
        self.group.scenario.update(modified: true)
      end
    end
  end

  def create_variables
    self.group.player_variables.each do |template|
      self.variables << template.instantiate
    end
  end

  def instances_stopped
    if group.instances.select{ |i| not i.stopped? }.size > 0
      errors.add(:running, 'instances with access must be stopped to add a player')
      return false
    end
    true
  end

  def password_hash
    UnixCrypt::SHA512.build(self.password)
  end
end
