class DownloadBashHistoryFromS3 < ApplicationJob

  def perform(instance)
    return if not instance.booted?

    contents = instance.get_bash_history

    Statistic.bash_histories_partition(contents.split("\n")).each do |user_name, commands|
      player = Player.joins(:group).find_by(login: user_name, groups: { scenario_id: instance.scenario.id })
      if player then
        commands.each do |timestamp, command|
          record = BashHistory.find_or_create_by!(
            instance: instance,
            player: player,
            command: command,
            performed_at: Time.at(timestamp.to_i).to_datetime
          )
        end
      end
    end

    # keep on doing it until the instance is no longer booted.
    instance.aws_instance_schedule_bash_history_download
  end

end
