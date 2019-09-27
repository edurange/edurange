class ImportBashHistories < ApplicationJob
  queue_as :scenario
  discard_on ActiveJob::DeserializationError

  def perform(scenario)
    return if not scenario.started?
    scenario.import_bash_histories!
    scenario.schedule_import_bash_histories!
  end
end
