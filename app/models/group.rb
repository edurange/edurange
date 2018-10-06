require 'variable'

class Group < ActiveRecord::Base
  belongs_to :scenario
  has_many :instance_groups, dependent: :destroy
  has_many :instances, through: :instance_groups
  has_many :players, dependent: :destroy
  has_one :user, through: :scenario

  validates :name, presence: true, uniqueness: { scope: :scenario, message: "Name taken" }
  validate :instances_stopped

  after_save :update_scenario_modified
  before_destroy :instances_stopped
  after_destroy :update_scenario_modified
  after_create :create_variable_hashes

  serialize :variables

  def update_scenario_modified
    if self.scenario.modifiable?
      return self.scenario.update_attribute(:modified, true)
    end
  end

  # return instances which the group has administrative access to
  def administrative_access_to
    instances = self.instance_groups.select {|instance_group| instance_group.administrator }.map {|instance_group| instance_group.instance}
  end

  # return true if the instances which this group has access to have stopped
  def instances_stopped
    self.instance_groups.each do |instance_group|
      if not instance_group.instance.stopped?
        errors.add(:running, "instances with access must be stopped before modificaton of group")
        return false
      end
    end
    true
  end

  def instances_stopped?
    self.instance_groups.each do |instance_group|
      if not instance_group.instance.stopped?
        errors.add(:running, 'instances with access must be stopped to modify group')
        return false
      end
    end
    true
  end

  # initialize the groups variables
  def create_variable_hashes
    self.update_attribute(:variables, { 
      instance: {}, 
      player: { 
        info: {},
        vars: {} 
      } 
    })
  end

  # return instances which the group has user level access to
  def user_access_to
    instances = self.instance_groups.select {|instance_group| !instance_group.administrator }.map {|instance_group| instance_group.instance}
  end

  # add a group of students to the group and return list of added players
  def student_group_add(student_group_name)
    if not self.instances_stopped?
      return []
    end

    players = []
    user = User.find(self.scenario.user.id)
    if not student_group = user.student_groups.find_by_name(student_group_name)
      errors.add(:name, "student group not found")
      return
    end
    student_group.student_group_users.each do |student_group_user|
      if not self.players.where("user_id = #{student_group_user.user_id} AND student_group_id = #{student_group.id}").first

        cnt = 1
        login = "#{student_group_user.user.name.filename_safe}"
        while self.players.find_by_login(login)
          cnt += 1
          login = login += cnt.to_s
        end

        player = self.players.new(
          login: login,
          password: SecureRandom.hex(4),
          user_id: student_group_user.user.id,
          student_group_id: student_group_user.student_group.id
        )
        player.save
        players.push(player)
      end
    end
    self.update_scenario_modified
    players
  end

  # remove a group of students from the group and return list of removed students
  def student_group_remove(student_group_name)
    if not self.instances_stopped?
      return []
    end

    players = []
    user = User.find(self.scenario.user.id)
    if not student_group = user.student_groups.find_by_name(student_group_name)
      errors.add(:name, "student group not found")
      return
    end
    student_group.student_group_users.each do |student_group_user|
      if player = self.players.find_by_user_id(student_group_user.user.id)
        players.push(player)
        player.destroy
      end
    end
    self.update_scenario_modified
    players
  end

  # return player object for player with matching student id
  def find_player_by_student_id(student_id)
    self.players.each do |player|
      if player.user
        return player if player.user.id == student_id
      end
    end
    nil
  end

  # update scenario instructions
  def update_instructions(instructions)
    self.update_attribute(:instructions, instructions)
    self.update_scenario_modified
  end

  # add an instance to the list of instances that the group has administrative access to
  def admin_access_add(instance)
    instance_group = self.instance_groups.new(instance_id: instance.id, administrator: true)
    if not instance_group.save
      errors.add(:instance_group, "could not create instance group: #{instance_group.errors.messages}")
    end
    return instance_group
  end

  # add an instance to the list of instances that the group has user level access to
  def user_access_add(instance)
    instance_group = self.instance_groups.new(instance_id: instance.id, administrator: false)
    if not instance_group.save
      errors.add(:instance_group, "could not create instance group: #{instance_group.errors.messages}")
    end
    return instance_group
  end

  # add variable to an instance
  def variable_instance_add(name, type, val)
    if self.variables[:instance].has_key? name
      errors.add(:variables, "already has Instance variable '#{name}'")
    end

    if not type
      errors.add(:variables, "must specify Instance variable type")
    end

    return false if errors.any?

    self.variables[:instance][name] = Variable.new(type, val) 

    self.save
  end

  # add variable to player
  def variable_player_add(name, type, val)
    puts self.instances
    if self.variables[:player][:info].has_key? name
      errors.add(:variables, "alread has Instance variable '#{name}'")
    end

    if not type
      errors.add(:variables, "must specity Instance variable type")
    end

    return false if errors.any?

    self.variables[:player][:info][name] = { type: type, val: val }

    self.players.each do |player|
      if not self.variables[:player][:vars].has_key? player
        self.variables[:player][:vars][player] = {}
      end
      self.variables[:player][:vars][player][name] = Variable.new(type, val)
    end

    self.save
  end

  # update player variable
  def variable_player_update(player)
    if not self.variables[:player][:vars].has_key? player
      self.variables[:player][:vars][player] = {}
    end
    self.variables[:player][:info].each do |name, hash|
      self.variables[:player][:vars][player][name] = Variable.new(hash[:type], hash[:val])
    end
    self.save
  end

  # remove player variable
  def variable_player_remove(player)
    if not self.variables[:player][:vars].has_key? player
      return
    end
    self.variables[:player][:vars].delete(player)
    self.save
  end

end
