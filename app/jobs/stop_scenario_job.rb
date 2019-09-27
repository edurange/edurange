class StopScenarioJob < ScenarioJob
  def perform(scenario)
    scenario.stop!
  end
end
