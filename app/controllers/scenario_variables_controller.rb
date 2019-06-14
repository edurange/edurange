
class ScenarioVariablesController < ApplicationController

  def destroy
    v = VariableTemplate.find(params.require(:id))
    v.destroy!
    flash[:notice] = "Variable '#{v.name}' removed"
    redirect_to action: :index
  end

  def index
    @scenario = find_scenario
    @user = current_user
    @variables = scenario.variables
  end

  def new
    @variable = VariableTemplate.new
  end

  def create
    @variable = VariableTemplate.new(variable_params)
    @variable.scenario = find_scenario

    if @variable.valid? then
      @variable.save!
      flash[:notice] = "Variable '#{@variable.name}' Added"
      redirect_to action: :index
    else
      render :new
    end
  end

  private

  def find_scenario
    Scenario.find(params.require(:scenario_id))
  end

  def variable_params
    params.require(:variable_template).permit(:name, :type, :value)
  end

end

