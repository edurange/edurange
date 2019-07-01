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
  has_many :student_groups, dependent: :destroy
  has_many :student_group_users, dependent: :destroy

  after_initialize :set_defaults, :if => :new_record?
  validates :registration_code, uniqueness: true, allow_blank: true

  before_validation do
    self.name = self.name.strip unless self.name.blank?
  end

  validates :name, presence: true
  validates :name, format: {
    with: /\A[a-zA-Z0-9_]+\z/,
  }

  validate :validate_running

  attr_accessor :invitee_registration_code

  validates :invitee_registration_code, presence: true, on: :create
  validates :invitee_registration_code, length: { is: REGISTRATION_CODE_LENGTH }, on: :create
  validate :validate_invitee_registration_code, on: :create

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
    # TODO: this was on production, evaluate if this is the correct behavior
    return true
    if self.scenarios.select{ |s| not s.stopped? }.size > 0
      errors.add(:running, "can not modify while a scenario is running")
      return false
    end
    true
  end

  def owns?(obj)
    return true if self.is_admin?
    cl = obj.class
    arr = [Cloud, Group, Instance, Scenario, StudentGroup, Subnet, InstanceRole, InstanceGroup, Role, RoleRecipe, Recipe, Answer]
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

  def is_admin?
    return self.role == 'admin'
  end

  def is_instructor?
    return self.role == 'instructor'
  end

  def is_student?
    return self.role == 'student'
  end

  def set_instructor_role
    if not self.registration_code
      self.update(registration_code: SecureRandom.hex(REGISTRATION_CODE_LENGTH / 2))
    end
    if not File.exists? "#{Rails.root}/scenarios/custom/#{self.id}"
      FileUtils.mkdir "#{Rails.root}/scenarios/custom/#{self.id}"
    end
    if not self.student_groups.find_by_name("All")
      sg = self.student_groups.new(name: "All")
      sg.save
    end
    self.update(role: :instructor)
  end

  def set_student_role
    if not self.validate_running
      return
    end
    self.student_groups.destroy_all
    self.update_attribute :role, :student
  end

  def set_admin_role
    if not self.registration_code
      self.update(registration_code: SecureRandom.hex[0..7])
    end
    if not File.exists? "#{Rails.root}/scenarios/custom"
      FileUtils.mkdir "#{Rails.root}/scenarios/custom"
    end
    if not File.exists? "#{Rails.root}/scenarios/custom/#{self.id}"
      FileUtils.mkdir "#{Rails.root}/scenarios/custom/#{self.id}"
    end
    if not self.student_groups.find_by_name("All")
      sg = self.student_groups.new(name: "All")
      sg.save
    end
    self.update(role: :admin)
  end

  def email_credentials(password)
    UserMailer.email_credentials(self, password).deliver_now
  end

  def student_to_instructor
    puts self.student_group_users.destroy_all
    self.student_group_users.destroy
    self.set_instructor_role
  end

  def student_add_to_all(student)
    if sg = self.student_groups.find_by_name("All")
      sgu = sg.student_group_users.new(user_id: student.id)
      sgu.save
    end
    return sg, sgu
  end

  def instructor_to_student(user)
    if user and (user.is_admin? or user.is_instructor?)
      if sg = user.student_groups.find_by_name("All")
        sgu = sg.student_group_users.new(user_id: self.id)
        sgu.save
      end
    end
    self.set_student_role
    return sg, sgu
  end

  def User.instructors_and_admins
    where(role: User.roles.fetch_values('admin', 'instructor'))
  end

end
