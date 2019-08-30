class CheckIfScenarioStillRunningJob < ApplicationJob
  queue_as :scenario
  def perform(scenario)
    if scenario.booted?
      UserMailer.scenario_time_warning(scenario.user.email).deliver_now
    end
  end
end
