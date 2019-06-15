
class VariablesController < ApplicationController

  def destroy
    v = VariableTemplate.find(params.require(:id))
    v.destroy!
    flash[:notice] = "Variable '#{v.name}' removed"
    redirect_to :back
  end

  private

  def variable_params
    params.require(:variable_template).permit(:name, :type, :value, :group_id, :scenario_id)
  end

end

