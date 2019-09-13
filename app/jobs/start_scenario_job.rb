class StartScenarioJob < ScenarioJob
  def perform(scenario)
    scenario = TerraformScenario.new(scenario)
    scenario.start!
  end
end
