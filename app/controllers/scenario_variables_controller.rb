class ScenarioVariablesController < VariablesController
  layout 'scenarios'
  before_action :authenticate_admin_or_instructor!

  def new
    @variable = VariableTemplate.new
    @variable.scenario = scenario
  end

  def create
    @variable = VariableTemplate.new(variable_params)
    if @variable.valid? then
      @variable.save!
      flash[:notice] = "Variable '#{@variable.name}' Added"
      redirect_to action: :index
    else
      render :new
    end
  end

  private

  helper_method def scenario
    @scenario ||= find_scenario
  end

  helper_method def variables
    scenario.variables
  end

  def find_scenario
    Scenario.find(params.require(:scenario_id))
  end

  before_action do
    @scenario = find_scenario
    @user = current_user
  end

end

