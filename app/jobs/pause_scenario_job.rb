
class PauseScenarioJob < ApplicationJob

  queue_as :scenario

  def perform(scenario)
    scenario.provider_pause_scenario
  end

end
