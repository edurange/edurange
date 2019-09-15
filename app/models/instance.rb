class Instance < ActiveRecord::Base
  belongs_to :scenario
  has_many :instance_groups, dependent: :destroy
  has_many :groups, through: :instance_groups, dependent: :destroy
  has_many :players, through: :groups
  has_many :bash_histories, dependent: :delete_all
  has_one :user, through: :scenario
  validates :name, presence: true, uniqueness: { scope: :scenario, message: "Name taken" }

  def owner?(id)
    return self.subnet.cloud.scenario.user_id == id
  end

end
