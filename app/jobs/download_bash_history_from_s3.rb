class DownloadBashHistoryFromS3 < ApplicationJob

  def perform(instance)
    return if not instance.booted?

    BashHistoryFile.parse(instance.get_bash_history).each do |user_name, commands|
      player = instance.players.find_by(login: user_name)
      if player then
        commands.each do |timestamp, command|
          BashHistory.find_or_create_by!(
            instance: instance,
            player: player,
            command: command,
            performed_at: Time.at(timestamp.to_i).to_datetime
          )
        end
      end
    end

    # download exit_statuses and correlate them with the command
    BashHistoryFile.parse_exit_statuses(instance.get_exit_status).each do |record|
      player = instance.players.find_by(login: record.player_login)
      logger.debug "exit statuses for player #{player.login} on instance #{instance.name}"
      if player then
        history = BashHistory.where("performed_at::time = :time", time: record.time).find_by(
          instance: instance,
          player: player,
        )
        history.update_attribute(:exit_status, record.exit_status) if history
      end
    end

    # keep on doing it until the instance is no longer booted.
    instance.aws_instance_schedule_bash_history_download
  end

end
