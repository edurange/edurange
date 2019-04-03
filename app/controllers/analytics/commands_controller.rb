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
      format.csv do
        render text: self.class.to_csv(@commands)
      end
    end
  end

  def self.to_csv commands
    CSV.generate(headers: true) do |csv|
      csv << %w{time scenario_id Scenario Instance Player Command}
      commands.each do |record|
        csv << [record.performed_at, record.scenario.id, record.scenario.name, record.instance.name, record.player.login, record.command]
      end
    end
  end

end
