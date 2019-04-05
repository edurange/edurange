class Analytics::CommandsController < ApplicationController
  include Pagy::Backend
  helper Pagy::Frontend

  def index
    @query = CommandHistoryQuery.new(filter_params)
    @pagy, @commands = pagy(@query.command_history)

    respond_to do |format|
      format.html
      format.csv
    end
  end

  def filter_params
    params.permit(CommandHistoryQuery::PARAMETERS)
  end

  class CommandHistoryQuery
    include ActiveModel::Model

    PARAMETERS = [:scenario_id, :player_login, :instance_name, :instance_id]

    attr_accessor *PARAMETERS

    def command_history
      rel = BashHistory.all
      rel = rel.with_scenario_id   scenario_id   if scenario_id.present?
      rel = rel.with_player_login  player_login  if player_login.present?
      rel = rel.with_instance_name instance_name if instance_name.present?
      rel = rel.with_instance_id   instance_id   if instance_id.present?
      rel
    end

    def scenario
      Scenario.find(scenario_id) if scenario_id.present?
    end

    def player_options
      scenario.players if scenario.present?
    end

    def instance_options
      scenario.instances if scenario.present?
    end

  end

end
