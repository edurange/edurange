class Instance < ActiveRecord::Base
  require 'open-uri'
  require 'csv'

  belongs_to :scenario
  has_many :instance_groups, dependent: :destroy
  has_many :groups, through: :instance_groups, dependent: :destroy
  has_many :players, through: :groups
  has_many :bash_histories, dependent: :delete_all
  has_one :user, through: :scenario


  validates :name, presence: true, uniqueness: { scope: :scenario, message: "Name taken" }

  after_destroy :update_scenario_modified

  def update_scenario_modified
    if self.scenario.modifiable?
      self.scenario.update_attribute(:modified, true)
    end
    true
  end

  # Add a role to the scenario
  def role_add(role_name)
    if not self.stopped?
      errors.add(:running, 'instance must be stopped to add role')
      return false
    end

    self.roles.each do |r|
      if r.name == role_name
        self.errors.add(:role_name, "Instance already has #{role_name}")
        return false
      end
    end

    if not role = self.scenario.roles.find_by_name(role_name)
      self.errors.add(:role_name, "Role does not exist")
      return false
    end
    ir = self.instance_roles.new(role_id: role.id)
    ir.save
    update_scenario_modified
    return ir
  end

  def owner?(id)
    return self.subnet.cloud.scenario.user_id == id
  end

#  def get_bash_history
#    provider_get_bash_history
#  end

  # def schedule_bash_history_download!
  #   DownloadBashHistory.set(wait: 1.minute).perform_later(self)
  # end
  #
  # def download_bash_history!
  #   csv = CSV.new(self.get_bash_history, col_sep: "\t", row_sep: "\n", quote_char: "\0")
  #
  #   csv.each do |row|
  #     begin
  #       self.bash_histories.find_or_create_by!(
  #         player: self.players.find_by(login: row[2]),
  #         exit_status: row[0].to_i,
  #         performed_at: Time.iso8601(row[1]),
  #         command: row[4]
  #       )
  #     rescue ActiveRecord::RecordInvalid
  #       logger.warn("could not save bash history record: #{$!}")
  #     end
  #   end
  # end
  #
  # def aws_get_bash_history
  #   if aws_s3_bash_history_object.exists?
  #     aws_s3_bash_history_object.get.body.read
  #   else
  #     ''
  #   end
  # end
  #
  # def aws_s3_bash_history_object
  #   aws_s3_instance_object('bash_history')
  # end
  #
  # def aws_s3_instance_object suffix
  #   aws_s3_bucket.object(aws_S3_object_name(suffix))
  # end
  #
  # def aws_s3
  #   @aws_s3 ||= Aws::S3::Resource.new
  # end
  #
  # def aws_s3_bucket_name
  #   "edurange-#{iam_user_name}"
  # end
  #
  # def aws_s3_bucket
  #   aws_s3.bucket(aws_s3_bucket_name)
  # end
  #
  # def iam_user_name
  #   @iam_user_name ||= AWS::IAM::Client.new.get_user.user.user_name
  # end

end
