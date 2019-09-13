# class DownloadBashHistory < ApplicationJob
#
#   def perform(instance)
#     return if not instance.booted?
#     instance.download_bash_history!
#     # keep on doing it until the instance is no longer booted.
#     instance.schedule_bash_history_download!
#   end
#
# end
