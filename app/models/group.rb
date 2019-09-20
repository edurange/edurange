class Group < ActiveRecord::Base
  belongs_to :scenario
  has_many :instance_groups, dependent: :destroy
  has_many :instances, through: :instance_groups
  has_many :players, dependent: :destroy
  has_one :user, through: :scenario

  has_many :variable_templates

  validates :name, presence: true, uniqueness: { scope: :scenario, message: "Name taken" }

  # add a group of students to the group and return list of added players
  def student_group_add(student_group_name)
    players = []
    if not student_group = self.scenario.user.student_groups.find_by_name(student_group_name)
      errors.add(:name, "student group not found")
      return
    end
    student_group.student_group_users.each do |student_group_user|
      if not self.players.where("user_id = #{student_group_user.user_id} AND student_group_id = #{student_group.id}").first

        cnt = 1
        login = "#{student_group_user.user.name.filename_safe}"
        while self.players.find_by_login(login)
          cnt += 1
          login = login += cnt.to_s
        end

        player = self.players.new(
          login: login,
          password: Player.random_password,
          user_id: student_group_user.user.id,
          student_group_id: student_group_user.student_group.id
        )
        player.save
        players.push(player)
      end
    end
    players
  end

  # remove a group of students from the group and return list of removed students
  def student_group_remove(student_group_name)
    if not self.scenario.stopped?
      return []
    end

    players = []
    user = User.find(self.scenario.user.id)
    if not student_group = user.student_groups.find_by_name(student_group_name)
      errors.add(:name, "student group not found")
      return
    end
    student_group.student_group_users.each do |student_group_user|
      if player = self.players.find_by_user_id(student_group_user.user.id)
        players.push(player)
        player.destroy
      end
    end
    players
  end

  def instantiate_variable(variable_template)
    self.players.each do |player|
      player.variables << variable_template.instantiate
    end
  end

end
