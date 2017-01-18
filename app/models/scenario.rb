class Scenario < ActiveRecord::Base
  include Provider
  require 'open-uri'

  # attr_accessor :template # For picking a template when creating a new scenario

  serialize :aws_prefixes
  
  belongs_to :user
  has_many :clouds, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_many :subnets, through: :clouds
  has_many :instances, through: :subnets
  has_one :statistic

  validate :validate_name, :validate_paths, :validate_user, :validate_stopped

  after_create :get_aws_prefixes, :load, :create_statistic
  # after_create :load
  # after_create :create_statistic

  before_destroy :validate_stopped, prepend: true
  before_destroy :save_questions_and_answers, prepend: true

  enum location: [:development, :production, :local, :custom, :test]

  def get_aws_prefixes
    content = open('https://ip-ranges.amazonaws.com/ip-ranges.json').read
    arr = JSON.parse(content)["prefixes"].select { |p| p["region"] == ENV["AWS_REGION"] }.map { |p| p["ip_prefix"] }
    self.update_attribute(:aws_prefixes, arr)
  end

  # Validations

  def validate_name
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
    true
  end

  def validate_paths
    if not self.path
      errors.add(:path, 'scenario with that name and location does not exist.')
      return false
    end
    if not self.path_yml
      errors.add(:path, 'could not find scenario yml file.')
      return false
    end
    if not self.path_recipes
      errors.add(:path, 'could not find scenario recipes folder.')
      return false
    end
  end

  def validate_stopped
    if not self.stopped?
      errors.add(:running, "can only modify scenario if it is stopped")
      return false
    end
    true
  end

  def validate_user
    if not self.user
      errors.add(:user, 'must have a user')
      return false
    end
    if not user = User.find_by_id(self.user)
      errors.add(:user, 'must have a user')
      return false
    end
    if not (user.is_admin? or user.is_instructor?)
      errors.add(:user, 'must be admin or instructor.')
      return
    end
  end

  # Statistics

  def save_questions_and_answers
    if self.statistic
      self.statistic.save_questions_and_answers
      self.statistic.save_scenario_yml
    end
  end

  # Loading and file structure

  def destroy_dependents
    self.clouds.each do |cloud| cloud.destroy end
    self.groups.each do |group| group.destroy end
    self.roles.each do |role| role.destroy end
    self.recipes.each do |recipe| recipe.destroy end
    self.questions.each do |question| question.destroy end
  end

  def load
    name_lookup_hash = Hash.new
    # Because in the YML we establish relationships by name we need to keep track of
    # what unique id corresponds to the current loading of the scenario. Whenever we
    # create an object, we store it within the above hash so that we can look it up
    # later in this function when we are creating objects referencing things in the database.
    
    begin
      file = YAML.load_file(self.path_yml)
      #file = YAML.load_file(Rails.root + self.path_yml)
      clouds = file["Clouds"]
      subnets = file["Subnets"]
      instances = file["Instances"]
      roles = file["Roles"]
      groups = file["Groups"]
      scoring = file["Scoring"]

      self.name = file["Name"]
      self.description = file["Description"]
      self.instructions = file["Instructions"] if file["Instructions"]
      self.instructions_student = file["InstructionsStudent"] if file["InstructionsStudent"]
      self.uuid = `uuidgen`.chomp
      self.answers = ''
      self.save

      ip_lookup_hash = {}

      roles_name_lookup_hash = {}
      if roles
        roles.each do |yaml_role|
          role = self.roles.new(name: yaml_role["Name"])

          if yaml_role["Recipes"]
            yaml_role["Recipes"].each do |recipe_name|

              recipe = self.recipes.find_by_name(recipe_name)
              if not recipe
                recipe = self.recipes.new(name: recipe_name)
              end


              if not recipe.save
                self.destroy_dependents
                errors.add(:load, "error creating recipe. #{recipe.errors.messages}")
                return false
              end


              role_recipe = role.role_recipes.new(recipe_id: recipe.id)
              if not role_recipe.save
                self.destroy_dependents
                errors.add(:load, "error creating role recipe. #{role_recipe.errors.messages}")
                return false
              end

            end
          end
          if yaml_role["Packages"]
            yaml_role["Packages"].each { |package| role.packages << package }
          end

          if not role.save
            self.destroy_dependents
            errors.add(:load, "error creating role. #{role.errors.messages}")
            return false
          end
          roles_name_lookup_hash[role.name] = role
        end
      end

      if clouds
        clouds.each do |yaml_cloud|

          cloud = self.clouds.new(name: yaml_cloud["Name"], cidr_block: yaml_cloud["CIDR_Block"])
          if not cloud.save
            self.destroy_dependents
            errors.add(:load, "error creating cloud. #{cloud.errors.messages}")
            return false
          end

          (yaml_cloud["Subnets"] ? yaml_cloud["Subnets"] : []).each do |yaml_subnet|

            subnet = cloud.subnets.new(
              name: yaml_subnet["Name"], 
              cidr_block: yaml_subnet["CIDR_Block"],
              internet_accessible: yaml_subnet["Internet_Accessible"] ? true : false
            )
            if not subnet.save
              self.destroy_dependents
              errors.add(:load, "error creating Subnet #{subnet.name}. #{subnet.errors.messages}")
              return false
            end

            instance_ips = {}
            (yaml_subnet["Instances"] ? yaml_subnet["Instances"] : []).each do |yaml_instance|

              instance = subnet.instances.new(
                name: yaml_instance["Name"],
                ip_address: yaml_instance["IP_Address"],
                ip_address_dynamic: yaml_instance["IP_Address_Dynamic"] ? yaml_instance["IP_Address_Dynamic"] : "",
                internet_accessible: yaml_instance["Internet_Accessible"] ? true : false,
                os: yaml_instance["OS"],
                uuid: `uuidgen`.chomp
              )
              if not instance.save or not instance.valid?
                self.destroy_dependents
                errors.add(:load, "error creating Instance #{instance.name}, #{instance.errors.messages}")
                return false
              end
              ip_lookup_hash[instance.name] = instance.ip_address

              (yaml_instance["Roles"] ? yaml_instance["Roles"] : []).each do |role_name|
                if not role = roles_name_lookup_hash[role_name]
                  errors.add(:load, 'role not found #{role_name}')
                  return false
                end
                instance.roles << role
              end

              name_lookup_hash[instance.name] = instance
            end
          end

        end
      end

      if groups
        groups.each do |yaml_group|

          users = yaml_group["Users"]
          access = yaml_group["Access"]
          admin = access["Administrator"]
          user = access["User"]

          group = self.groups.new(name: yaml_group["Name"], instructions: yaml_group["Instructions"])
          if not group.save
            self.destroy_dependents
            errors.add(:load, "error creating group. #{group.errors.messages}")
            return false
          end

          if users
            users.each do |yaml_user|

              user_id = nil
              if user = User.find_by_id(yaml_user["Id"])
                user_id = user.is_student? ? user.id : nil
              end

              player = group.players.new(
                login: yaml_user["Login"],
                password: yaml_user["Password"],
                user_id: user_id
              )

              if not player.save
                self.destroy_dependents
                errors.add(:load, "error creating player. #{player.errors.messages}")
                return false
              end

            end
          end

          # Give group admin on machines they own
          if admin
            if admin["IP_Visible"]
              admin["IP_Visible"].each do |admin_instance|
                if instance = name_lookup_hash[admin_instance]
                  instance.add_administrator(group, true)
                  if not instance.save
                    self.destroy_dependents
                    errors.add(:load, "error adding group access admin to instance #{instance.name}, #{instance.errors.messages}")
                    return false
                  end
                else
                  self.destroy_dependents
                  errors.add(:load, "error adding admin access. Instance #{admin_instance} not found.")
                  return false
                end
              end
            end
            if admin["IP_Hidden"]
              admin["IP_Hidden"].each do |admin_instance|
                if instance = name_lookup_hash[admin_instance]
                  instance.add_administrator(group, false)
                  if not instance.save
                    self.destroy_dependents
                    errors.add(:load, "error adding group access admin to instance #{instance.name}, #{instance.errors.messages}")
                    return false
                  end
                else
                  self.destroy_dependents
                  errors.add(:load, "error adding admin access. Instance #{admin_instance} not found.")
                  return false
                end
              end
            end
          end

          user = access["User"]
          if user
            if user["IP_Visible"]
              user["IP_Visible"].each do |user_instance|
                if instance = name_lookup_hash[user_instance]
                  instance.add_user(group, true)
                  if not instance.save
                    self.destroy_dependents
                    errors.add(:load, "error adding group access user to instance #{instance.name}")
                    return false
                  end
                else
                  self.destroy_dependents
                  errors.add(:load, "error adding user access. Instance #{user_instance} not found.")
                  return false
                end
              end
            end
            if user["IP_Hidden"]
              user["IP_Hidden"].each do |user_instance|
                if instance = name_lookup_hash[user_instance]
                  instance.add_user(group, false)
                  if not instance.save
                    self.destroy_dependents
                    errors.add(:load, "error adding group access user to instance #{instance.name}")
                    return false
                  end
                else
                  self.destroy_dependents
                  errors.add(:load, "error adding user access. Instance #{user_instance} not found.")
                  return false
                end
              end
            end
          end
        end
      end

      # Do scoring
      if scoring
        self.reload
        scoring.each do |yaml_question|

          question = self.questions.new(
            type_of: yaml_question['Type'], 
            text: yaml_question['Text'],
            points: yaml_question["Points"],
            order: yaml_question["Order"],
            options: yaml_question["Options"] ? yaml_question['Options'] : [],
            values: yaml_question["Values"] ? yaml_question['Values'].map { |val|
              ({ value: val["Value"], points: val["Points"] })
            } : []
          )

          if not question.save
            self.destroy_dependents
            errors.add(:load, "error adding question. #{question.errors.messages}")
            return false
          end

        end
      end
    rescue => e
      self.destroy_dependents
      errors.add(:load, e.class.to_s + ' - ' + e.message.to_s + "\n" + e.backtrace.join("\n"))
      return false
    end

    if self.test? or self.development? or self.custom?
      self.update_attribute(:modifiable, true)
    end

    self.reload
    self.update_attribute(:modified, false)
  end

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

    yml["Roles"] = self.roles.empty? ? nil : self.roles.map { |r|
      { "Name"=>r.name, 
        "Packages" => r.packages.empty? ? nil : r.packages, 
        "Recipes"=>r.recipes.empty? ? nil : r.recipes.map { |rec| rec.name }
      }
    }

    yml["Groups"] = self.groups.empty? ? nil : self.groups.map { |group| 
      { "Name" => group.name,
        "Instructions" => group.instructions,
        "Access" => { 
          "Administrator" => group.instance_groups.none? {|ig| ig.administrator} ? nil : {
            "IP_Visible" => group.instance_groups.select{ |ig| ig.administrator and ig.ip_visible }.map{ |ig| ig.instance.name },
            "IP_Hidden" => group.instance_groups.select{ |ig| ig.administrator and not ig.ip_visible }.map{ |ig| ig.instance.name }
            },
          "User" => group.instance_groups.none? {|ig| not ig.administrator} ? nil : {
            "IP_Visible" => group.instance_groups.select{ |ig| not ig.administrator and ig.ip_visible }.map{ |ig| ig.instance.name },
            "IP_Hidden" => group.instance_groups.select{ |ig| not ig.administrator and not ig.ip_visible }.map{ |ig| ig.instance.name }
          }
        },
        "Users" => group.players.empty? ? nil : group.players.map { |p| { 
          "Login" => p.login, 
          "Password" => p.password, 
          "Id" => self.has_student?(p.user) ? p.user_id : nil,
          "UserId" => p.user_id,
          "StudentGroupId" => p.student_group_id
          } 
        }
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
        "Values" => question.values == nil ? nil : question.values.map { |vals| { "Value" => vals[:special] == '' ? vals[:value] : vals[:special], "Points" => vals[:points] } },
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
      path = "#{Rails.root}/scenarios/custom/#{self.user.id}/#{self.name.downcase}"
    else
      path = "#{Rails.root}/scenarios/#{self.location}/#{self.name.downcase}"
    end
    return path if File.exists? path
    false
  end

  def path_yml
    path = "#{self.path}/#{self.name.downcase}.yml"
    return path if File.exists? path
    false
  end

  def path_recipes
    path = "#{self.path}/recipes"
    if not File.exists? path
      FileUtils.mkdir path
    end
    return path
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

  def players
    players = []
    self.clouds.each do |cloud|
      cloud.subnets.each do |subnet|
        subnet.instances.each do |instance|
          instance.instance_groups.each do |instance_group|
            instance_group.group.players.each do |player|
              found = false
              players.each do |inplayer|
                if inplayer.login == player.login
                  found = true
                end
              end
              if !found
                players.push(player)
              end
            end
          end
        end
      end
    end
    return players
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

  def instances_initialized?
    self.instances.select{ |i| i.initialized? == "true" }.size == self.instances.size
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
    nat = self.instances.select{|i| i.internet_accessible and i.os == "nat" }
    (nat.any? ? nat.first : nil)
  end

  def data_path
    path = "#{Rails.root}/data/#{Rails.env}/#{self.user.id}/#{self.created_at.strftime("%y_%m_%d")}_#{self.name}_#{self.id}"
    FileUtils.mkdir_p(path) if not File.exists?(path)
    path
  end

  def data_path_instances
    path = "#{self.data_path}/instances"
    FileUtils.mkdir_p(path) if not File.exists?(path)
    path
  end

  def data_path_boot
    path = "#{self.data_path}/boot"
    FileUtils.mkdir_p(path) if not File.exists?(path)
    path
  end

  private

    def create_statistic
      statistic = Statistic.new(scenario_id: self.id)
      statistic.save
      # statistic.save_bash_histories_exit_status_script_log
      # statistic.save_questions_and_answers
    end

end
  
