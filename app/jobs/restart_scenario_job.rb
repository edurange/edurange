class RestartScenarioJob < ScenarioJob
  def perform(scenario)
    scenario.restart!
  end
end
