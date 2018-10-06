class Instance < ActiveRecord::Base
  include Provider # This is where the AWS stuff is coming from
  require 'open-uri'
  require 'dynamic_ip'

  belongs_to :subnet
  has_many :instance_groups, dependent: :destroy
  has_many :instance_roles, dependent: :destroy
  has_many :groups, through: :instance_groups, dependent: :destroy
  has_many :roles, through: :instance_roles, dependent: :destroy
  has_one :user, through: :subnet
  has_one :scenario, through: :subnet

  serialize :ip_address_dynamic

  validates_presence_of :name, :os, :subnet
  validates :name, presence: true, uniqueness: { scope: :subnet, message: "Name taken" } 
  validate :validate_stopped, :validate_internet_accessible, :validate_ip_address

  after_destroy :update_scenario_modified
  before_destroy :validate_stopped 
  after_save :update_statistic
  
  def update_statistic
    statistic = self.scenario.statistic
    if statistic
      statistic.gen_info
    end
  end

  # Check to see if the instance has stopped
  def validate_stopped
    if not self.stopped?
      errors.add(:running, "can not modify while scenario is booted")
      return false
    end
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  # Check if the instance can access the internet
  def validate_internet_accessible
    if self.internet_accessible and not self.subnet.internet_accessible
      errors.add(:internet_accessible, "Instances subnet must also be internet accessible")
    end
  end
  
  # Check if the instance has a valid IP
  def validate_ip_address
    if not self.ip_address_dynamic == "" and self.ip_address_dynamic and not self.has_dynamic_ip?
      dip = DynamicIP.new(self.ip_address_dynamic)
      if dip.error?
        errors.add(:ip_address_dynamic, "DynamicIP error: #{dip.error}")
        return false
      end
      self.update_attribute(:ip_address_dynamic, dip)
      if not self.ip_address or self.ip_address == ""
        self.update_attribute(:ip_address, dip.ip)
      else
        dip.ip = self.ip_address
        self.update_attribute(:ip_address_dynamic, dip)
      end
    end

    ip = IPAddress.valid_ipv4?(self.ip_address)
    if not ip
      errors.add(:ip_address, "IP address is not valid")
      return false
    end

    if not NetAddr::CIDR.create(self.subnet.cidr_block).cmp(self.ip_address)
      errors.add(:ip_address, "IP address is not within instances subnet #{self.subnet.name} #{self.subnet.cidr_block}")
      return false
    end

    self.subnet.instances.each do |instance|
      next if self == instance
      if self.ip_address == instance.ip_address
        errors.add(:ip_address, "IP address is taken")
        return false
      end
    end

    if self.ip_address.split('.').last.to_i <= 3
      errors.add(:ip_address, "the last octect of your ip address must be greater than 3. numbers less than 4 are reserved")
      return false
    end
  end

  def ip_roll
    if self.ip_address_dynamic
      self.ip_address_dynamic.roll
      self.update_attribute(:ip_address, self.ip_address_dynamic.ip)
      self.update_scenario_modified
    end
  end

  def update_scenario_modified
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  def has_dynamic_ip?
    return self.ip_address_dynamic.respond_to?(:octets)
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

  # Get the cloud scenario and return it
  def scenario
    return self.subnet.cloud.scenario
  end

  # Return the owner of the scenario
  def owner?(id)
    return self.subnet.cloud.scenario.user_id == id
  end

  # Return the status of instance
  # Marked for refactoring
  def status_check
    puts "\nstatus check\n"
    if self.driver_id
      if AWS::EC2.new.instances[self.driver_id].exists? 
        # check if it is running
      else
        self.driver_id = nil
        self.set_stopped
        self.save
      end
    end
  end

  # Return the bash history for the instance
  # Mark for refactoring
  def get_bash_history
    return "" if (!self.bash_history_page or (self.bash_history_page == ""))

    begin
      s3 = AWS::S3.new 
      bucket = s3.buckets[Rails.configuration.x.aws['s3_bucket_name']]
      if bucket.objects[self.aws_S3_object_name('bash_history')].exists?
        bash_history =  bucket.objects[self.aws_S3_object_name('bash_history')].read()
        return bash_history == nil ? "" : bash_history
      end
    rescue => e
      return "error getting bash history: #{e}"
    end

    return ""
  end

  def get_exit_status
    return "" if (!self.exit_status_page or (self.exit_status_page == ""))

    begin
      s3 = AWS::S3.new
      bucket = s3.buckets[Rails.configuration.x.aws['s3_bucket_name']]
      if bucket.objects[self.aws_instance_exit_status_page_name].exists?
        exit_status =  bucket.objects[self.aws_instance_exit_status_page_name].read()
        return exit_status == nil ? "" : exit_status
      end
    rescue
      return "error getting exit status"
    end

    return ""
  end

  # Return script log
  # Marked for refactoring
  def get_script_log
    return "" if (!self.script_log_page or (self.script_log_page == ""))

    begin
      s3 = AWS::S3.new
      bucket = s3.buckets[Rails.configuration.x.aws['s3_bucket_name']]
      if bucket.objects[self.aws_instance_script_log_page_name].exists?
        script_log =  bucket.objects[self.aws_instance_script_log_page_name].read()
        return script_log == nil ? "" : script_log
      end
    rescue
      return "error getting script log"
    end

    return ""
  end

  # Return chef erros
  # Marked for refactoring
  def get_chef_error
    return "" if !self.bash_history_page
    s3 = AWS::S3.new
    bucket = s3.buckets[Rails.configuration.x.aws['s3_bucket_name']]
    if bucket.objects[self.aws_S3_object_name('com')].exists?
      chef_err =  bucket.objects[self.aws_S3_object_name('com')].read()
      return chef_err == nil ? "" : chef_err
    end
    return ""
  end

  # Check if the instance is initialized
  def initialized?
    return "-" if !self.com_page

    begin
      com_page = AWS::S3.new.buckets[Rails.configuration.x.aws['s3_bucket_name']].objects[self.aws_S3_object_name('com')]
      if com_page.exists?
        text = com_page.read()
        status = text.split("\n")[0]
        if status == "error"
          return "chef script error"
        elsif status == "finished"
          return "true"
        end
      end
    rescue AWS::S3::Errors::NoSuchKey
      return false
    end
    "initializing"
  end

  def port_open?(ip, port)
    begin
      Timeout::timeout(1) do 
        begin
          s = TCPSocket.open(ip, port)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          return false
        end
      end
    rescue Timeout::Error
    end
    return false
  end

  def ssh_ready?
    if ip = self.ip_address_public
      if (self.port_open?(ip, 22))
        return true
      end
    end
    return false
  end

  # Marked for refactoring
  def s3_name_prefix
    scenario = self.subnet.cloud.scenario
    return scenario.user.name + scenario.name + scenario.id.to_s + scenario.uuid
  end
 
  def add_progress(val)
    # debug "Adding progress to instance!"
    # PrivatePub.publish_to "/scenarios/#{self.subnet.cloud.scenario.id}", instance_progress: val
  end

  def generate_init
    begin
      # Returns the bash code to initialize an instance with chef-solo
      init = ""
      os_bootstrap_path = "#{Rails.root}/scenarios/bootstrap/os_#{self.os.filename_safe}.sh.erb"
      if File.exists? os_bootstrap_path
        init += Erubis::Eruby.new(File.read(os_bootstrap_path)).result(instance: self) + "\n"
      end

      # initiate chef
      init += Erubis::Eruby.new(File.read(Rails.root + "scenarios/bootstrap/chef.sh.erb")).result(instance: self) + "\n"

      # do routing rules
      # routing_rules = Erubis::Eruby.new(File.read(Rails.root + "scenarios/bootstrap/ip_tables.sh.erb")).result(instance: self) + "\n"
      # s3_routing_rules = ''
      # self.scenario.aws_prefixes.each do |aws_prefix|
      #   s3_routing_rules += "iptables -A OUTPUT -d #{aws_prefix} -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT\n"
      #   s3_routing_rules += "iptables -A INPUT -d #{aws_prefix} -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT\n"
      # end
      # init += routing_rules.gsub("<s3_routing_rules>", s3_routing_rules)

      # enable ssh password login by default
      init += Erubis::Eruby.new(File.read(Rails.root + "scenarios/bootstrap/sshd_password_login.sh.erb")).result(instance: self) + "\n"

      # message of the day
      motd_folder_path = self.scenario.path + '/motd'
      if not File.exists? motd_folder_path
        FileUtils.mkdir motd_folder_path
      end
      motd_path = motd_folder_path + '/' + self.name.filename_safe
      if File.exists? motd_path
        motd = File.open(motd_path, 'r').read().gsub("\n", "\\n").gsub("\t", "\\t").gsub("\"", "\\\"")

        init += 'echo -e "' + motd + '" >> /etc/motd'
      end

      init
    rescue
      raise
      return
    end
  end
  
  # Marked for refactoring
  def generate_cookbook
    begin
      # Find out if this is a global or custom recipe
      scenario_path = "#{Rails.root}/scenarios/user/#{self.scenario.user.name.filename_safe}/#{self.scenario.name.filename_safe}"
      scenario_path = "#{Rails.root}/scenarios/local/#{self.scenario.name.filename_safe}" if not File.exists? scenario_path

      # This recipe sets up packages and users and is run for every instance
      cookbook = Erubis::Eruby.new(File.read("#{Rails.root}/scenarios/recipes/default/packages_and_users.rb.erb")).result(instance: self) + "\n"

      self.roles.each do |role|
        role.recipes.each do |recipe|
          if recipe.custom
            cookbook += recipe.text + "\n"
          else
            cookbook += Erubis::Eruby.new(recipe.text).result(instance: self) + "\n"
          end
        end
      end

      # This recipe signals the com page and also gets the bash histories
      cookbook += Erubis::Eruby.new(File.read("#{Rails.root}/scenarios/recipes/default/com_page_and_bash_histories.rb.erb")).result(instance: self) + "\n"
      # This recipe changes /etc/bash.bashrc so that the bash history is written to file with every command
      cookbook += Erubis::Eruby.new(File.read("#{Rails.root}/scenarios/recipes/default/write_bash_histories.rb.erb")).result(instance: self) + "\n"
      
      # do iptables rules
      routing_rules = Erubis::Eruby.new(File.read(Rails.root + "scenarios/bootstrap/ip_tables.sh.erb")).result(instance: self) + "\n"
      s3_routing_rules = ''
      self.scenario.aws_prefixes.each do |aws_prefix|
        s3_routing_rules += "iptables -A OUTPUT -d #{aws_prefix} -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT\n"
        s3_routing_rules += "iptables -A INPUT -d #{aws_prefix} -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT\n"
      end
      cookbook += routing_rules.gsub("<s3_routing_rules>", s3_routing_rules)

      cookbook
    rescue
      raise
      return
    end
  end

  # Names of students participating in the scenario instance
  def player_names
    names = []
    self.groups.each do |g|
      g.players.each { |p| names << p.login }
    end
    names
  end

  # Handy user methods
  def administrators
    groups = self.instance_groups.select {|instance_group| instance_group.administrator }.map {|instance_group| instance_group.group}
    users = groups.inject([]) {|users, group| users.concat(group.players) }
  end

  def users
    groups = self.instance_groups.select {|instance_group| !instance_group.administrator }.map {|instance_group| instance_group.group}
    users = groups.inject([]) {|users, group| users.concat(group.players) }
  end

  def add_administrator(group, ip_visible)
    InstanceGroup.create(group: group, instance: self, administrator: true, ip_visible: ip_visible)
  end

  def add_user(group, ip_visible)
    InstanceGroup.create(group: group, instance: self, administrator: false, ip_visible: ip_visible)
  end

  def variables_instance
    vars = {}
    self.groups.each do |g|
      vars = vars.merge(g.variables[:instance]) if g.variables[:instance]
    end
    vars
  end

  def variables_player
    vars = {}
    self.groups.each do |g|
      g.variables[:player][:vars].each do |player, v|
        if not vars.has_key? player
          vars[player] = {}
        end
        vars[player] = vars[player].merge(v)
      end
    end
    vars
  end
end
