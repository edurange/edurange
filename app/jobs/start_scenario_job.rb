class StartScenarioJob < ScenarioJob
  def perform(scenario)
    scenario.start!
  end
end
