class Analytics::CommandsController < ApplicationController
  def index
    @commands = BashHistory.all
  end
end
