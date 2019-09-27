class StudentGroup < ActiveRecord::Base
  belongs_to :user
  has_many   :student_group_users, dependent: :destroy
  has_many :users, through: :student_group_users

  validates :name, presence: true, uniqueness: { scope: :user, message: "Name taken" }
  before_save :make_registration_code

  # before_destroy :check_if_all

  # def check_if_all
  # 	if self.name == "All"
  # 		errors.add(:name, "can not delete Student Group All")
  # 		return false
  # 	end
  # 	true
  # end

  def registration_code
    super || user.registration_code
  end

  def add_users(to_add)
    to_add = [*to_add]
    new_to_add = to_add - self.users
    self.users << new_to_add
    return new_to_add
  end

  def remove_users(users)
    self.users.destroy(users)
  end

  def make_registration_code
    if not self.name == "All"
      if not self.registration_code
        self.update(registration_code: SecureRandom.hex[0..7])
      end
    end
  end

end
