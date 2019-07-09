class DownloadBashHistory < ApplicationJob

  # If the instance is deleted after the job is enqueued but before the #perform method is called Active Job will raise an ActiveJob::DeserializationError exception.
  # If this happens, abandon the job.
  rescue_from('ActiveJob::DeserializationError') do |exception|
    logger.warn("Discarding because of ActiveJob::DeserializationError")
  end

  def perform(instance)
    return if not instance.booted?
    instance.download_bash_history!
    # keep on doing it until the instance is no longer booted.
    instance.schedule_bash_history_download!
  end

end
