
# NOTE: I have taken the liberty to rename the concept of 'start' to 'resume' here, as 'start' is ambiguous while 'resume' clearly implies the scenario must be paused beforehand.
class ResumeScenarioJob < ApplicationJob

  queue_as :scenario

  def perform(scenario)
    scenario.provider_start_scenario
  end

end
