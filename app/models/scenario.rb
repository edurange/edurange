class Scenario < ActiveRecord::Base
  include Provider
  require 'open-uri'

  #  as a string
  enum location: [:development, :production, :local, :custom, :test]

  # Associations
  # http://guides.rubyonrails.org/association_basics.html
  belongs_to :user
  has_many :clouds, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :subnets, through: :clouds
  has_many :instances, through: :subnets
  has_many :players, through: :groups

  has_many :variable_templates
  has_many :variables

  # Validations
  # http://guides.rubyonrails.org/active_record_validations.html
  validates_associated :clouds, :questions, :roles, :recipes, :groups, :user
  validates :user, presence: true
  validates :name, presence: true, format: { without: /\A_*_\z/ }
  validates :name, format: { with: /\A\w*\z/,
                             message: "can only contain alphanumeric and underscore" }
  validate :paths_exist, :validate_stopped, :owner_is_instructor_or_admin

  # Custom validations methods
  # http://guides.rubyonrails.org/active_record_validations.html#custom-methods

  def paths_exist
    errors.add(:path, "#{path} does not exist") unless File.exists? path
    errors.add(:path, "#{path_yml} does not exist") unless File.exists? path_yml
    errors.add(:path, "#{path_recipes} does not exist") unless File.exists? path_recipes
  end

  def validate_stopped
    errors.add(:base, 'You can only update a scenario when it is stopped.') unless stopped? or not changed?
  end

  def owner_is_instructor_or_admin
    unless self.user.admin? or self.user.instructor?
      errors.add(:user, 'Only admins and instructors create scenarios.')
    end
  end

  validate do
    if changed? and archived? and not archived_changed? then
      errors.add(:base, "You can not update an archived scenario.")
    end
  end

  # Callbacks
  # http://guides.rubyonrails.org/active_record_callbacks.html
  after_create :modifiable_check
  before_destroy :validate_stopped, prepend: true

  # File structure

  def update_yml
    if not self.modifiable?
      self.errors.add(:customizable, "Scenario is not modifiable.")
      return false
    end
    if not self.modified?
      self.errors.add(:modified, "Scenario is not modified.")
      return false
    end

    yml = {
      "Name" => self.name,
      "Description" => self.description,
      "Instructions" => self.instructions,
      "InstructionsStudent" => self.instructions_student,
      "Groups" => nil,
      "Clouds" => nil,
      "Subnets" => nil,
      "Instances" => nil
    }

    if not self.variable_templates.blank?
      yml['Variables'] = self.variable_templates.map{ |v| {
        "Name"  => v.name,
        "Type"  => v.type,
        "Value" => v.value
      }}
    end

    yml["Roles"] = self.roles.empty? ? nil : self.roles.map { |r|
      { "Name"=>r.name,
        "Packages" => r.packages.empty? ? nil : r.packages,
        "Recipes"=>r.recipes.empty? ? nil : r.recipes.map { |rec| rec.name }
      }
    }

    yml["Groups"] = self.groups.empty? ? nil : self.groups.map { |group|
      { "Name" => group.name,
        "Instructions" => group.instructions,
        "Access" => group.instance_groups.empty? ? nil : group.instance_groups.map { |access|
          { "Instance" => access.instance.name,
            "Administrator" => access.administrator,
            "IP_Visible" => access.ip_visible
          }
        },
        "Users" => group.players.empty? ? nil : group.players.map { |p| {
          "Login" => p.login,
          "Password" => p.password,
          "Id" => self.has_student?(p.user) ? p.user_id : nil,
          "UserId" => p.user_id,
          "StudentGroupId" => p.student_group_id
          }
        },

        "Variables" => group.variable_templates.empty? ? nil : group.variable_templates.map { |v| {
          "Name"  => v.name,
          "Type"  => v.type,
          "Value" => v.value
        }}
      }
    }

    yml["Clouds"] = self.clouds.empty? ? nil : self.clouds.map { |cloud|
      {
      "Name" => cloud.name,
      "CIDR_Block" => cloud.cidr_block,
      "Subnets" => cloud.subnets.empty? ? nil : cloud.subnets.map { |subnet|
        {
        "Name" => subnet.name,
        "CIDR_Block" => subnet.cidr_block,
        "Internet_Accessible" => subnet.internet_accessible,
        "Instances" => subnet.instances.empty? ? nil : subnet.instances.map { |instance|
          {
          "Name" => instance.name,
          "OS" => instance.os,
          "IP_Address" => instance.ip_address,
          "IP_Address_Dynamic" => instance.has_dynamic_ip? ? instance.ip_address_dynamic.str : nil,
          "Internet_Accessible" => instance.internet_accessible,
          "Roles" => instance.roles.map { |r| r.name }
          }
        }}
      }}
    }

    yml["Scoring"] = self.questions.empty? ? nil : self.questions.map { |question| {
        "Text" => question.text,
        "Type" => question.type_of,
        "Options" => question.options,
        "Values" => question.values == nil ? nil : question.values.map { |vals| { "Value" => vals[:special] == '' || vals[:special] == nil ? vals[:value] : vals[:special], "Points" => vals[:points] } },
        "Order" => question.order,
        "Points" => question.points
      }
    }

    f = File.open("#{self.path}/#{self.name.downcase}.yml", "w")
    f.write(yml.to_yaml)
    f.close()
    self.update_attribute(:modified, false)
  end

  def path
    if self.custom?
      "#{Rails.root}/scenarios/custom/#{self.user.id}/#{self.name.downcase}"
    else
      "#{Rails.root}/scenarios/#{self.location}/#{self.name.downcase}"
    end
  end

  def path_yml
    "#{self.path}/#{self.name.downcase}.yml"
  end

  def path_recipes
    path = "#{self.path}/recipes"
    FileUtils.mkdir(path) unless File.exists?(path) or not File.exists?(self.path)
    path
  end

  def modifiable_check
    if self.test? or self.development? or self.custom?
      self.update_attribute(:modifiable, true)
    end
  end

  def update_modified
    if self.modifiable?
      self.update_attribute(:modified, true)
    end
  end

  def change_name(name)
    if not self.stopped?
      errors.add(:running, "can not modify while scenario is not stopped");
      return false
    end

    name = name.strip
    if name == ""
      errors.add(:name, "Can not be blank")
    elsif /\W/.match(name)
      errors.add(:name, "Name can only contain alphanumeric and underscore")
    elsif /^_*_$/.match(name)
      errors.add(:name, "Name not allowed")
    elsif not self.modifiable?
      errors.add(:custom, "Scenario must be modifiable to change name")
    elsif not self.stopped?
      errors.add(:running, "Scenario must be stopped before name can be changed")
    elsif File.exists? "#{Rails.root}/scenarios/local/#{name.downcase}/#{name.downcase}.yml"
      errors.add(:name, "Name taken")
    elsif File.exists? "#{Rails.root}/scenarios/user/#{self.user.id}/#{name.downcase}/#{name.downcase}.yml"
      errors.add(:name, "Name taken")
    else
      oldpath = "#{Rails.root}/scenarios/user/#{self.user.id}/#{self.name.downcase}"
      newpath = "#{Rails.root}/scenarios/user/#{self.user.id}/#{name.downcase}"
      FileUtils.cp_r oldpath, newpath
      FileUtils.mv "#{newpath}/#{self.name.downcase}.yml", "#{newpath}/#{name.downcase}.yml"
      FileUtils.rm_r oldpath
      self.name = name
      self.save
      self.update_yml
      true
    end
    false
  end

  def owner?(id)
    return self.user_id == id
  end

  def scenario
    return self
  end

  def students
    students = []
    self.groups.each do |group|
      group.players.each do |player|
        students << player.user if not students.include? player.user and player.user
      end
    end
    students
  end

  def questions_answered(user)
    return nil if not self.has_student? user

    answered = 0
    self.questions.each do |question|
      answered += 1 if question.answers.where("user_id = ?", user.id).size > 0
    end
    answered
  end

  def questions_correct(user)
    return nil if not self.has_student? user

    correct = 0
    self.questions.each do |question|
      # correct += 1 if question.answers.where("user_id = ? AND correct = 1", user.id).size > 0
      question.answers.where("user_id = ?", user.id).each do |answer|
        correct += 1 if answer.correct
      end
    end
    correct
  end

  def public_instances_reachable?
    reachable
    return self.instances.select{ |i| not i.port_open?(22) }.any?
  end

  def check_status
    return
    cnt = 0
    stopped = 0
    queued_boot = 0
    queued_unboot = 0
    booted = 0
    booting = 0
    unbooting = 0
    boot_failed = 0
    unboot_failed = 0
    paused = 0
    pausing  = 0
    starting = 0

    self.clouds.each do |cloud|
      cloud.reload
      cnt += 1
      stopped += 1 if cloud.stopped?
      queued_boot += 1 if cloud.queued_boot?
      queued_unboot += 1 if cloud.queued_unboot?
      booted += 1 if cloud.booted?
      booting += 1 if cloud.booting?
      unbooting += 1 if cloud.unbooting?
      boot_failed += 1 if cloud.boot_failed?
      unboot_failed += 1 if cloud.unboot_failed?

      cloud.subnets.each do |subnet|
        subnet.reload
        cnt += 1
        stopped += 1 if subnet.stopped?
        queued_boot += 1 if subnet.queued_boot?
        queued_unboot += 1 if subnet.queued_unboot?
        booted += 1 if subnet.booted?
        booting += 1 if subnet.booting?
        unbooting += 1 if subnet.unbooting?
        boot_failed += 1 if subnet.boot_failed?
        unboot_failed += 1 if subnet.unboot_failed?

        subnet.instances.each do |instance|
          instance.reload
          cnt += 1
          stopped += 1 if instance.stopped?
          queued_boot += 1 if instance.queued_boot?
          queued_unboot += 1 if instance.queued_unboot?
          booted += 1 if instance.booted?
          paused += 1 if instance.paused?
          pausing += 1 if instance.pausing?
          starting += 1 if instance.starting?
          booting += 1 if instance.booting?
          unbooting += 1 if instance.unbooting?
          boot_failed += 1 if instance.boot_failed?
          unboot_failed += 1 if instance.unboot_failed?
        end
      end
    end

    if boot_failed > 0
      self.set_boot_failed
    elsif unboot_failed > 0
      self.set_unboot_failed
    elsif booting > 0
      self.set_booting
    elsif unbooting > 0
      self.set_unbooting
    elsif queued_boot > 0
      self.set_queued_boot
    elsif queued_unboot > 0
      self.set_queued_unboot
    elsif paused > 0
      self.set_paused
    elsif pausing > 0
      self.set_pausing
    elsif starting > 0
      self.set_starting
    elsif booted > 0
      if booted == cnt
        self.set_booted
      else
        self.set_partially_booted
      end
    else
      self.set_stopped
    end
  end

  def get_global_recipes_and_descriptions
    recipes = { }
    Dir.foreach("#{Rails.root}/scenarios/recipes") do |file|
      next if file == '.' or file == '..'

      recipe = file.gsub(".rb.erb", "")
      description = ''
      description_file = "#{Rails.root}/scenarios/recipes/descriptions/#{recipe}"
      if File.exists? description_file
        description += File.open(description_file).read
      end
      recipes[recipe] = description 
    end
    recipes
  end

  def clone(name)
    ScenarioManagement.new.clone_from_name(self.name, self.location, name, self.user)
  end

  def obliterate
    if not self.custom?
      self.errors.add(:obliterate, "can not obliterate non cusom scenario")
      return false
    end
    name, path_graveyard_scenario = ScenarioManagement.new.obliterate_custom(self.name, self.user)
    self.destroy
    return path_graveyard_scenario
  end

  def make_custom
    self.name = self.name.strip
    if self.name == ""
      errors.add(:name, "Can not be blank")
      return false
    elsif /\W/.match(self.name)
      errors.add(:name, "Name can only contain alphanumeric and underscore")
      return false
    elsif /^_*_$/.match(self.name)
      errors.add(:name, "Name not allowed")
      return false
    end

    if File.exists? "#{Rails.root}/scenarios/local/#{self.name.downcase}"
      errors.add(:name, "A global scenario with that name already exists")
      return false
    end

    if File.exists? "#{Rails.root}/scenarios/user/#{self.user.id}/#{self.name.downcase}"
      errors.add(:name, "A custom scenario with that name already exists")
      return false
    end

    FileUtils.mkdir self.path
    FileUtils.mkdir "#{self.path}/recipes"
    self.update_attribute(:modified, true)
    self.update_yml

    return true
  end

  def has_student?(user)
    return false if not user
    self.groups.each do |group| 
      return true if group.players.select { |p| p.user == user }.size > 0
    end
    false
  end

  def has_question?(question)
    self.questions.find_by_id(question.id) != nil
  end

  def answer_cnt(user)
    return nil if not has_student?(user)
    cnt = 0
    self.questions.each do |question|
      cnt += question.answers.where("user_id = ?", user.id).size
    end
    cnt
  end

  def answers_list(user)
    return nil if not has_student?(user)
    answers = []
    self.questions.each do |question|
      answers += question.answers.map { |a| a.id }
    end
    answers
  end

  def find_student(user_id)
    self.groups.each do |group| 
      group.players.each do |player|
        if player.user
          return player.user if player.user.id == user_id
        end
      end
    end
    nil
  end

  def students_groups(user)
    groups = []
    self.groups.each do |group|
      group.players.each do |player|
        if player.user
          groups << group if player.user == user
        end
      end
    end
    groups
  end

  def update_instructions(instructions)
    self.update_attribute(:instructions, instructions)
    self.update_modified
  end

  def update_instructions_student(instructions)
    self.update_attribute(:instructions_student, instructions)
    self.update_modified
  end

  def status_update
    self.reload
    if self.descendents.select { |d| d.boot_scheduled? or d.booting? or d.boot_fail? }.any?
      self.update_attribute(:status, :booting)
    elsif self.descendents.select { |d| d.unboot_scheduled? or d.unbooting? or d.unboot_fail? }.any?
      self.update_attribute(:status, :unbooting)
    elsif self.descendents.select { |d| d.stopped? }.size == self.descendents.size
      self.update_attribute(:status, :stopped)
    elsif self.descendents.select { |d| d.booted? }.size == self.descendents.size
      self.update_attribute(:status, :booted)
    else
      self.update_attribute(:status, :booted_partial)
    end
  end

  def nat_instance
    self.instances.select{|i| i.internet_accessible and i.os == "nat" }.first
  end

  def data_path
    path = "#{Rails.root}/data/#{Rails.env}/#{self.user.id}/#{self.created_at.strftime("%y_%m_%d")}_#{self.name}_#{self.id}"
    FileUtils.mkdir_p(path) if not File.exists?(path)
    path
  end

  def data_path_boot
    path = "#{self.data_path}/boot"
    FileUtils.mkdir_p(path) if not File.exists?(path)
    path
  end

  def instantiate_variable template
    self.variables << template.instantiate
  end

  def self.load(**args)
    ScenarioLoader.new(args).fire!
  end

  def guide_exists?
    guide_path.exist?
  end

  def guide
    guide_path.read
  end

  def guide_path
    documentation_path + "#{self.name.downcase}.md"
  end

  def solution
    solution_path.read
  end

  def solution_path
    documentation_path + "#{self.name.downcase}_solution.md"
  end

  def solution_exists?
    solution_path.exist?
  end

  def documentation_path
    Rails.root.join('app', 'views', 'tutorials', 'documentation', 'scenarios')
  end

  def can_boot?
    bootable?
  end

  def can_unboot?
    unbootable?
  end

  def can_save?
    modified? and modifiable
  end

  def can_destroy?
    stopped?
  end

  def can_archive?
    stopped?
  end

  def can_unarchive?
    archived?
  end

  # pausing/resuming does not work so disable in the UI
  def can_pause?
    false
  end

  def can_resume?
    false
  end

end
