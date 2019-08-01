class BashHistory < ActiveRecord::Base
  belongs_to :instance
  belongs_to :player

  has_one :scenario, through: :player

  validates :command, presence: true
  validates :performed_at, presence: true

  def self.with_scenario_id scenario_id
    joins(:scenario).where(scenarios: {id: scenario_id})
  end

  def self.with_player_login player_login
    joins(:player).where(players: { login: player_login })
  end

  def self.with_instance_name instance_name
    joins(:instance).where(instances: { name: instance_name })
  end

  def self.with_instance_id instance_id
    where(instance_id: instance_id)
  end

  def self.with_scenario_owner user
    joins(:scenario).where(scenarios: {user_id: user.id})
  end

  def self.with_user user
    joins(:player).where(players: { user_id: user.id })
  end

end
