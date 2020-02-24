class Schedule < ActiveRecord::Base
  belongs_to :user

  before_validation :set_scenario_location, :set_uuid
  before_save :available_resources, :not_past
  after_destroy :remove_resources

  def set_uuid
    self.uuid = `uuidgen`[0..7]
  end

  def set_scenario_location
    @user = User.find(self.user_id)
    templates = []
    scenario_list = []
    if Rails.env == 'production'
      templates << YmlRecord.yml_headers('production', @user)
      templates << YmlRecord.yml_headers('local', @user)
    elsif Rails.env == 'development'
      templates << YmlRecord.yml_headers('development', @user)
      templates << YmlRecord.yml_headers('production', @user)
      templates << YmlRecord.yml_headers('local', @user)
      templates << YmlRecord.yml_headers('test', @user)
    elsif Rails.env == 'test'
      templates << YmlRecord.yml_headers('test', @user)
    end
    templates << YmlRecord.yml_headers('custom', @user)
    templates.each {|x| x.each {|y| scenario_list.push([y[:name], y[:location]])}}
    scenario_list.each do |x|
      if self.scenario == x[0]
        self.scenario_location = x[1]
      end
    end
  end

  def remove_resources
    Calendar.delete_event(self.user, "#{self.scenario} #{self.uuid}", self.start_time, self.end_time)
  end

  def available_resources
    count_instances
    if Calendar.check_resources(self.user, "#{self.scenario} #{self.uuid}", @instance_count, self.start_time, self.end_time)
      return true
    else
      errors.add(:scenario, "- EDUrange does not have enough resources to boot this scenario in this time frame.")
      false
    end
  end

  def count_instances
    @instance_count = 0
    file = YAML.load_file(self.get_yml)
    subnets = file["Clouds"][0]["Subnets"]
    subnets.each do |subnet|
      instances = subnet["Instances"]
      instances.each do |instance|
        @instance_count += 1
      end
    end
    return @instance_count
  end

  def get_yml
    if self.scenario_location == "custom"
      @yml_path = "#{Rails.root}/scenarios/custom/#{self.user.id}/#{self.scenario.downcase}/#{self.scenario.downcase}.yml"
    else
      @yml_path = "#{Rails.root}/scenarios/#{self.scenario_location}/#{self.scenario.downcase}/#{self.scenario.downcase}.yml"
    end
    return @yml_path if File.exists? @yml_path
    false
  end

  def not_past
    if self.end_time - self.start_time <=0
      errors.add(:end_time, "- Scenario must end after it starts")
      return false
    end
    true
  end

end
