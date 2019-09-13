class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable

  REGISTRATION_CODE_LENGTH = 8

  enum role: {
    admin: 2,
    instructor: 3,
    student: 4
  }

  has_many :scenarios, dependent: :destroy
  has_many :schedules
  has_many :student_groups, dependent: :destroy, autosave: true
  has_many :student_group_users, dependent: :destroy, autosave: true

  after_initialize :set_defaults
  validates :registration_code, uniqueness: true, allow_blank: true
  validates :registration_code, presence: true, unless: :student?

  before_validation do
    self.name = self.name.strip unless self.name.blank?
  end

  validates :name, presence: true
  validates :name, format: {
    with: /\A[a-zA-Z0-9_]+\z/,
  }

  validate :validate_running

#  validate def has_all_student_group
#    if self.admin? or self.instructor?
#      unless self.student_groups.find_by_name('All')
#        self.errors.add('Admins and Instructors must have default student group.')
#      end
#    end
#  end

  attr_accessor :invitee_registration_code

  validates :invitee_registration_code, presence: true, on: :create, if: :is_student?
  validates :invitee_registration_code, length: { is: REGISTRATION_CODE_LENGTH }, on: :create, if: :is_student?
  validate :validate_invitee_registration_code, on: :create, if: :is_student?

  def invited_to_student_group
    StudentGroup.find_by_registration_code(self.invitee_registration_code) if invitee_registration_code.present?
  end

  def invited_by_instructor_or_admin
    User.instructors_and_admins.find_by_registration_code(self.invitee_registration_code) if invitee_registration_code.present?
  end

  def validate_invitee_registration_code
    if self.invitee_registration_code.present?
      unless invited_to_student_group || invited_by_instructor_or_admin
        self.errors.add :invitee_registration_code, :invalid
      end
    end
  end

  after_create def add_to_student_groups
    if invited_to_student_group
      logger.debug("Adding #{self.email} to #{invited_to_student_group.name} and All")
      invited_to_student_group.users << self
      invited_by = invited_to_student_group.user
      all_student_group = invited_by.student_groups.find_by(name: 'All')
      all_student_group.users << self
    end

    if invited_by_instructor_or_admin
      logger.debug("Adding #{self.email} to All")
      all_student_group = invited_by_instructor_or_admin.student_groups.find_by(name: 'All')
      all_student_group.users << self
    end
  end

  def validate_running
    if self.changed? and self.scenarios.select{ |s| not s.stopped? }.size > 0
      errors.add(:running, "can not modify while a scenario is running")
    end
  end

  def owns?(obj)
    return true if self.is_admin?
    cl = obj.class
    arr = [Group, Instance, Scenario, StudentGroup, InstanceGroup, Answer]
    if arr.include? cl
      return obj.user == self
    elsif cl == Player
      return obj.group.user == self
    elsif cl == StudentGroupUser
      return obj.student_group.user == self
    end
  end

  def set_defaults
    self.role ||= :student
  end

  alias is_admin?      admin?
  alias is_instructor? instructor?
  alias is_student?    student?

  def self.generate_registration_code
    SecureRandom.hex(REGISTRATION_CODE_LENGTH / 2)
  end

  def role=(role)
    case role
    when 'student'
      self.registration_code = nil
      # students should not have any student_groups
      self.student_groups.each do |student_group|
        student_group.mark_for_destruction
      end
    when 'admin', 'instructor'
      self.registration_code ||= self.class.generate_registration_code
      self.create_custom_scenario_path!
      # admins and instructors should not be in any student groups
      self.student_group_users.each do |student_group_user|
        student_group_user.mark_for_destruction
      end
      self.student_groups.find_or_initialize_by(name: "All")
    end
    super(role)
  end

  def create_custom_scenario_path!
    if not File.exists? "#{Rails.root}/scenarios/custom"
      FileUtils.mkdir "#{Rails.root}/scenarios/custom"
    end
    if not File.exists? "#{Rails.root}/scenarios/custom/#{self.id}"
      FileUtils.mkdir "#{Rails.root}/scenarios/custom/#{self.id}"
    end
  end

  def User.new_instructor(params)
    User.new(params.merge(password: SecureRandom.hex(16), role: 'instructor'))
  end

  def email_credentials(password)
    UserMailer.email_credentials(self, password).deliver_now
  end

  def student_to_instructor
    self.role = 'instructor'
    self.save!
  end

  def student_add_to_all(student)
    if self.is_admin? or self.is_instructor? then
      if sg = self.student_groups.find_by_name("All")
        sgu = sg.student_group_users.new(user_id: student.id)
        sgu.save
      end
      return sg, sgu
    end
  end

  def instructor_to_student(user)
    self.role = 'student'
    self.save
    return user.student_add_to_all(self)
  end

  def User.instructors_and_admins
    where(role: User.roles.fetch_values('admin', 'instructor'))
  end

  def User.students
    where(role: 'student')
  end

  def User.instructors
    where(role: 'instructor')
  end

end
