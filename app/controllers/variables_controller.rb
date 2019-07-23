class VariablesController < ApplicationController
  before_action :authenticate_admin_or_instructor!

  def destroy
    v = VariableTemplate.find(params.require(:id))
    v.destroy!
    redirect_back(fallback_location: v.scenario, notice: "Variable '#{v.name}' removed")
  end

  private

  def variable_params
    params.require(:variable_template).permit(:name, :type, :value, :group_id, :scenario_id)
  end

end
