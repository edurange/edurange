class ScenarioCommandsController < CommandsController
  layout 'scenarios'
  def index
    super
    @scenario = Scenario.find(params.require(:scenario_id))
  end
end
