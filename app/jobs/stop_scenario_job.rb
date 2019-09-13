class StopScenarioJob < ScenarioJob
  def perform(scenario)
    scenario = TerraformScenario.new(scenario)
    scenario.stop!
  end
end
