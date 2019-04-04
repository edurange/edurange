require 'csv'

class Analytics::CommandsController < ApplicationController
  def index
    @commands = BashHistory.joins(:scenario, :player, :instance).order(:performed_at)
    @commands = @commands.where(scenarios: { id: params[:scenario_id] }) if params[:scenario_id].present?
    @commands = @commands.where(players: {login: params[:player_login]}) if params[:player_login].present?
    @commands = @commands.where(instances: {name: params[:instance_name]}) if params[:instance_name].present?
    @commands = @commands.where(instances: {id: params[:instance_id]}) if params[:instance_id].present?

    respond_to do |format|
      format.html
      format.csv
    end
  end
end
