class InvalidYAMLError < StandardError; end

class ScenarioLoader
  # - Working on ScenarioLoader?
  # Check out the spec (spec/lib/scenario_loader_spec.rb)
  # Be sure to run it regularly with `rspec spec/lib/scenario_loader_spec.rb` to verify
  # your code works and modify it as needed if you change the functionality of
  # ScenarioLoader.
  #
  # - Wonder where ScenarioLoader is called from?
  # See ScenariosController#create (app/controllers/scenarios_controller.rb)

  def initialize(**args)
    @user = args[:user]
    @name = args[:name]
    @location = args[:location] || :production
  end

  def fire!
    @scenario = Scenario.new(user: @user, name: @name, location: @location)
    create_scenario! if @scenario.save
  end

  private

  def create_scenario!
    begin
      load_metadata
      build_roles
      build_clouds
      build_groups
      build_variables(@scenario, yaml['Variables'])
      @scenario.reload
      build_questions
    rescue => e
      binding.pry if Rails.env.development? || Rails.env.test?
      @scenario.errors.add(:load, "Exception caught during loading: #{e}. "\
                                  "See log for details.")
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
    end

    @scenario.reload
  end

  def yaml
    return nil unless @scenario
    @yaml ||= YAML.load_file(@scenario.path_yml)
  end

  def load_metadata
    @scenario.update!(
      name: yaml["Name"],
      description: yaml["Description"],
      instructions: yaml["Instructions"],
      instructions_student: yaml["InstructionsStudent"],
      uuid: SecureRandom.uuid
    )
  end

  # Roles
  def build_roles
    return if yaml["Roles"].nil?
    raise InvalidYAMLError unless yaml["Clouds"].respond_to? :each

    yaml["Roles"].each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      @scenario.roles.create!(name: hash["Name"],
                              packages: hash["Packages"],
                              recipes: recipes_from_names(hash["Recipes"]))
    end
  end

  def recipes_from_names(names)
    return [] if names.nil?
    raise InvalidYAMLError unless names.respond_to? :map
    names.map { |n| @scenario.recipes.find_or_create_by(name: n) }
  end

  # Clouds
  def build_clouds
    return if yaml["Clouds"].nil?
    raise InvalidYAMLError unless yaml["Clouds"].respond_to? :each

    yaml["Clouds"].each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      cloud = @scenario.clouds.create!(name: hash["Name"], cidr_block: hash["CIDR_Block"])
      build_subnets(cloud, hash["Subnets"])
    end
  end

  # Subnets
  def build_subnets(cloud, subnet_hashes)
    return if subnet_hashes.nil? || cloud.invalid?
    raise InvalidYAMLError unless subnet_hashes.respond_to? :each

    subnet_hashes.each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      subnet = cloud.subnets.create!(name: hash["Name"],
                                     cidr_block: hash["CIDR_Block"],
                                     internet_accessible: hash["Internet_Accessible"])
      build_instances(subnet, hash["Instances"])
    end
  end

  # Instances
  def build_instances(subnet, instance_hashes)
    return if instance_hashes.nil? || subnet.invalid?
    raise InvalidYAMLError unless instance_hashes.respond_to? :each

    instance_hashes.each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      subnet.instances.create!(
        name: hash["Name"],
        ip_address: hash["IP_Address"],
        ip_address_dynamic: hash["IP_Address_Dynamic"],
        internet_accessible: hash["Internet_Accessible"],
        os: hash["OS"],
        uuid: SecureRandom.uuid,
        roles: roles_from_names(hash["Roles"])
      )
    end
  end

  def roles_from_names(names)
    return [] if names.nil?
    names.map { |n| @scenario.roles.find_by(name: n) }.reject(&:nil?)
  end

  # Groups
  def build_groups
    return if yaml["Groups"].nil?
    raise InvalidYAMLError unless yaml["Groups"].respond_to? :each

    yaml["Groups"].each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      group = @scenario.groups.create!(name: hash["Name"],
                                       instructions: hash["Instructions"])
      build_players(group, hash["Users"])
      build_instance_groups(group, hash["Access"])
      if hash["Variables"]
        build_variables(group, hash["Variables"])
      end
    end
  end

  def build_variables(entity, variables)
    return if variables.nil?
    raise InvalidYAMLError unless variables.respond_to? :each

    variables.each do |var|
      entity.variable_templates.create(
        name:  var['Name'],
        type:  var['Type'],
        value: var['Value']
      )
    end
  end

  # Players
  def build_players(group, player_hashes)
    return if player_hashes.nil?
    raise InvalidYAMLError unless player_hashes.respond_to? :each

    player_hashes.each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      if hash["UserId"]
        if user = User.find(hash["UserId"])
          group.players.create!(
            login: hash["Login"],
            password: hash["Password"], 
            student_group_id: hash["StudentGroupId"], 
            user: user
          )
        end
      else
        group.players.create!(login: hash["Login"], password: hash["Password"])
      end
    end
  end

  # InstaceGroups
  def build_instance_groups(group, access)
    return if access.nil?
    raise InvalidYAMLError unless access.respond_to? :each

    access.each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      group.instance_groups.create!(
        instance: @scenario.instances.find_by_name(hash["Instance"]),
        administrator: hash["Administrator"],
        ip_visible: hash["IP_Visible"]
      )
    end
  end

  # Scoring
  def build_questions
    return if yaml["Scoring"].nil?
    raise InvalidYAMLError unless yaml["Scoring"].respond_to? :each

    yaml["Scoring"].each do |hash|
      raise InvalidYAMLError unless hash.respond_to? :[]
      @scenario.questions.create!(
        type_of: hash["Type"],
        text: hash["Text"],
        points: hash["Points"],
        order: hash["Order"],
        options: hash["Options"],
        values: format_values(hash["Values"])
      )
    end
  end

  def format_values(values)
    return nil unless values.respond_to? :each
    values.map { |value| { value: value["Value"], points: value["Points"] } }
  end
end
