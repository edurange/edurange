class Scenario < ActiveRecord::Base
  require 'open-uri'

  enum location: [:development, :production, :local, :custom, :test]

  enum status: {
    stopped: 0,
    started: 4,
    starting: 2,
    stopping: 12,
    error: 3,
  }

  belongs_to :user
  has_many :questions, dependent: :destroy
  has_many :groups,    dependent: :destroy
  has_many :instances,  dependent: :destroy
  has_many :players, through: :groups

  has_many :variable_templates
  has_many :variables

  validates_associated :questions, :groups, :user
  validates :user, presence: true
  validates :name, presence: true, format: { without: /\A_*_\z/ }
  validates :name, format: { with: /\A\w*\z/,
                             message: "can only contain alphanumeric and underscore" }
  validate :paths_exist, :owner_is_instructor_or_admin

  def paths_exist
    errors.add(:path, "#{path} does not exist") unless File.exists? path
    errors.add(:path, "#{path_yml} does not exist") unless File.exists? path_yml
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

  after_create :modifiable_check
  before_destroy :validate_stopped, prepend: true

  # def update_yml
  #   if not self.modifiable?
  #     self.errors.add(:customizable, "Scenario is not modifiable.")
  #     return false
  #   end
  #   if not self.modified?
  #     self.errors.add(:modified, "Scenario is not modified.")
  #     return false
  #   end
  #
  #   yml = {
  #     "Name" => self.name,
  #     "Description" => self.description,
  #     "Instructions" => self.instructions,
  #     "InstructionsStudent" => self.instructions_student
  #   }
  #
  #   if not self.variable_templates.blank?
  #     yml['Variables'] = self.variable_templates.map{ |v| {
  #       "Name"  => v.name,
  #       "Type"  => v.type,
  #       "Value" => v.value
  #     }}
  #   end
  #
  #   if !self.groups.empty? then
  #     yml["Groups"] =  self.groups.map do |group|
  #       {
  #         "Name" => group.name,
  #         "Instructions" => group.instructions,
  #         "Access" => group.instance_groups.empty? ? nil : group.instance_groups.map do |access|
  #           {
  #             "Instance" => access.instance.name,
  #             "Administrator" => access.administrator,
  #             "IP_Visible" => access.ip_visible
  #           }
  #         end,
  #         "Users" => group.players.empty? ? nil : group.players.map do |p|
  #           {
  #             "Login" => p.login,
  #             "Password" => p.password
  #           }
  #         end,
  #         "Variables" => group.variable_templates.empty? ? nil : group.variable_templates.map do |v|
  #           {
  #             "Name"  => v.name,
  #             "Type"  => v.type,
  #             "Value" => v.value
  #           }
  #         end
  #     }
  #   end
  # end
  #
  #   if !subnet.instances.empty? then
  #     yml['Instances'] = subnet.instances.map do |instance|
  #       {
  #         'Name' => instance.name
  #       }
  #     end
  #   end
  #
  #   yml["Scoring"] = self.questions.empty? ? nil : self.questions.map { |question| {
  #       "Text" => question.text,
  #       "Type" => question.type_of,
  #       "Options" => question.options,
  #       "Values" => question.values == nil ? nil : question.values.map { |vals| { "Value" => vals[:special] == '' || vals[:special] == nil ? vals[:value] : vals[:special], "Points" => vals[:points] } },
  #       "Order" => question.order,
  #       "Points" => question.points
  #     }
  #   }
  #
  #   f = File.open("#{self.path}/#{self.name.downcase}.yml", "w")
  #   f.write(yml.to_yaml)
  #   f.close()
  #   self.update_attribute(:modified, false)
  # end

  def path
    Rails.root.join('scenarios', scenario.location, scenario.name.downcase)
  end

  def path_yml
    path.join("#{self.name.downcase}.yml")
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
    Rails.root.join('documentation', 'scenarios')
  end

  def can_start?
    !started? & !archived?
  end

  def can_stop?
    !stopped? & !archived?
  end

  def can_destroy?
    stopped?
  end

  def can_archive?
     !archived? & stopped?
  end

  def can_unarchive?
    archived?
  end

  # list all scenarios available to create
  def self.templates
    Rails.root.join('scenarios').children.flat_map do |location|
      if location.directory? then
        location.children.flat_map do |scenario|
          if scenario.directory?
            yml_path = scenario.join("#{scenario.basename}.yml")
            hash = YAML.load_file(yml_path)
            Scenario.new(
              name: hash['Name'],
              location: location.basename.to_s,
              description: hash['Description']
            )
          end
        end
      end
    end
  end

  def import_bash_histories!
    s3 = Aws::S3::Resource.new(region: 'us-east-1')
    bucket = s3.bucket('edurange')
    objects = bucket.objects(prefix: "scenarios/#{scenario.uuid}/bash_history/")
    objects.each do |object|
      object.get.body.read.each_line do |line|
        record = JSON.parse(line)
        begin
          BashHistory.find_or_create_by!(
            instance:     self.instances.find_by_name(record['hostname'].gsub('-', '_')),
            player:       self.players.find_by_login(record['user']),
            exit_status:  record['exit_code'].to_i,
            performed_at: Time.iso8601(record['time']),
            command:      record['cmd']
          )
        rescue ActiveRecord::RecordInvalid
          logger.warn("could not save bash history record: #{$!}")
        end
      end
      object.delete
    end
  end

  def schedule_import_bash_histories!
    ImportBashHistories.set(wait: 1.minute).perform_later(self)
  end

end
