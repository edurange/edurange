class StudentScenarioCommandsController < CommandsController
  layout 'student_scenarios'
  def index
    super
    @scenario = Scenario.find(params.require(:scenario_id))
  end
end
