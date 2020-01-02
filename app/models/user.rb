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

  attribute :role, default: 4

  has_many :scenarios, dependent: :destroy
  has_many :schedules

  has_many :student_groups,
    dependent: :destroy,
    autosave: true

  has_many :student_group_users,
    dependent: :destroy,
    autosave: true

  has_many :member_of_student_groups,
    through: :student_group_users,
    source: :student_group

  validates :registration_code, uniqueness: true, allow_blank: true
  validates :registration_code, presence: true, unless: :student?

  before_validation do
    self.name = self.name.strip unless self.name.blank?
  end

  validates :name, presence: true
  validates :name, format: {
    with: /\A[a-zA-Z0-9_]+\z/,
  }

  validate def has_all_student_group
    if self.admin? or self.instructor?
      unless self.student_groups.select{|g| g.name == 'All'}.size == 1
        self.errors.add(:base, 'Admins and Instructors must have default student group.')
      end
    end
  end

  validate def student_in_student_group_all
    if self.student?
      unless self.student_group_users.select{|sgu| sgu.student_group.name == 'All'}.size == 1
        errors.add(:base, "Student #{self.name} not in a student group 'All'")
      end
    end
  end

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

  after_initialize def add_to_student_groups
    if invited_to_student_group
      logger.debug("Adding #{self.email} to #{invited_to_student_group.name} and All")
      self.student_group_users.build(student_group: invited_to_student_group)
      invited_by = invited_to_student_group.user
      all_student_group = invited_by.student_groups.find_by(name: 'All')
      self.student_group_users.build(student_group: all_student_group)
    end

    if invited_by_instructor_or_admin
      logger.debug("Adding #{self.email} to All")
      all_student_group = invited_by_instructor_or_admin.student_groups.find_by(name: 'All')
      self.student_group_users.build(student_group: all_student_group)
    end
  end

  validate def validate_running
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

  alias is_admin?      admin?
  alias is_instructor? instructor?
  alias is_student?    student?

  def self.generate_registration_code
    SecureRandom.hex(REGISTRATION_CODE_LENGTH / 2)
  end

  def self.generate_password
    SecureRandom.hex(16)
  end

  def User.new_instructor(params)
    User.new(params.merge(
      password: User.generate_password,
      registration_code: User.generate_registration_code,
      role: 'instructor',
      student_groups: [StudentGroup.new(name: 'All')]
    ))
  end

  def email_credentials(password)
    UserMailer.email_credentials(self, password).deliver_now
  end

  def student_to_instructor
    User.transaction do
      self.student_groups.find_or_create_by!(name: "All")
      self.role = 'instructor'
      self.member_of_student_groups.destroy_all
      self.registration_code = self.class.generate_registration_code


      logger.debug("hello #{self.role}")

      self.save!
    end
  end

  def student_group_all
    self.student_groups.find_by_name("All")
  end

  def member_of_student_group_all
    self.member_of_student_groups.find_by_name("All")
  end

  def instructor_to_student(admin)
    unless student?
      User.transaction do
        self.registration_code = nil
        self.student_groups.each do |student_group|
          student_group.mark_for_destruction
        end
        self.student_group_users.create(student_group: admin.student_group_all)
        self.role = 'student'
        self.save
      end
    else
      logger.warn("User #{name} is already a student")
    end
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
