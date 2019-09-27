require 'unix_crypt'
class Player < ActiveRecord::Base
  belongs_to :group
  validates_presence_of :group
  belongs_to :student_group
  belongs_to :user
  has_one :scenario, through: :group
  has_many :bash_histories, dependent: :delete_all
  has_many :variables, dependent: :destroy

  validates :login, presence: true, uniqueness: { scope: :group, message: "name already taken" }
  validates :password, presence: true

  after_create :create_variables

  before_validation do
    if password.blank?
      self.password = Player.random_password
    end
  end

  def self.random_password
    SecureRandom.hex(4)
  end

  def create_variables
    self.group.variable_templates.each do |template|
      self.variables << template.instantiate
    end
  end

  def password_hash
    UnixCrypt::SHA512.build(self.password)
  end
end
