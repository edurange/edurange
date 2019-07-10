class StudentGroupUser < ActiveRecord::Base
  belongs_to :student_group
  belongs_to :user

  validates :user, presence: true, uniqueness: { scope: :student_group, message: "already exists" }
end
