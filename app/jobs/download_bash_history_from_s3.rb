class DownloadBashHistoryFromS3 < ApplicationJob

  # If the instance is deleted after the job is enqueued but before the #perform method is called Active Job will raise an ActiveJob::DeserializationError exception.
  # If this happens, abandon the job.
  rescue_from ActiveJob::DeserializationError do |exception|
    logger.warn("Discarding because of #{exception}")
  end

  def perform(instance)
    return if not instance.booted?

    BashHistoryFile.import_bash_history_for_instance(instance, instance.get_bash_history)
    BashHistoryFile.import_exit_status_for_instance(instance, instance.get_exit_status)

    # keep on doing it until the instance is no longer booted.
    instance.aws_instance_schedule_bash_history_download
  end

end
