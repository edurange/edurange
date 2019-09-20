class DownloadTTYLog < ApplicationJob

  def perform(instance)
    return if not instance.booted?
    instance.download_ttylog!
    #keep on doing it until the instance is no longer booted.
    instance.schedule_ttylog_download!
  end

end
