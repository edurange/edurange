
class VariablesController < ApplicationController

  def index
    @variables = Variable.where(group_id: params[:group_id])
  end

  def new
    @variable = Variable.new
  end

  def create
    @group = Group.find(params.require(:group_id))
    @variable = Variable.new(variable_params)
    @variable.group = @group
    if @variable.valid? then
      @group.variables << @variable
      redirect_to group_variables_url, alert: 'Variable Added'
    else
      render :new
    end
  end

  private

  def variable_params
    params.require(:variable).permit(:name, :type, :value, :template, :group_id)
  end

end

