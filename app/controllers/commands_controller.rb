class CommandsController < ApplicationController
  include Pagy::Backend
  helper Pagy::Frontend

  before_action :authenticate_user!

  # TODO
  # Admins should have access to all scenarios, instances, and players.
  # Instructors should have access to the instance and players of scenarios they own.
  # Students should have access to the scenarios and instances they are players in, and only view their own commands.

  def index
    @query = CommandHistoryQuery.new(filter_params.merge(current_user: current_user))
    @pagy, @commands = pagy(@query.command_history)

    respond_to do |format|
      format.html
      format.csv
    end
  end

  helper_method def filter_params
    params.permit(CommandHistoryQuery::PARAMETERS)
  end

  class CommandHistoryQuery
    include ActiveModel::Model

    PARAMETERS = [:scenario_id, :player_login, :instance_name, :instance_id]

    attr_accessor *PARAMETERS
    attr_accessor :current_user

    def command_history
      rel = BashHistory.order(performed_at: :desc)
      rel = rel.with_scenario_id    scenario_id   if scenario_id.present?
      rel = rel.with_player_login   player_login  if player_login.present?
      rel = rel.with_instance_name  instance_name if instance_name.present?
      rel = rel.with_instance_id    instance_id   if instance_id.present?
      rel = rel.with_user           current_user  if current_user.student?
      rel = rel.with_scenario_owner current_user  if current_user.instructor?
      rel
    end

    def scenario
      Scenario.find(scenario_id) if scenario_id.present?
    end

    def player_options
      scenario.players if scenario.present? and not current_user.student?
    end

    def instance_options
      scenario.instances if scenario.present?
    end

  end

end
