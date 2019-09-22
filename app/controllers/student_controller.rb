class StudentController < ApplicationController
  before_action :authenticate_student!

  def show
    @scenarios = []
    current_user.players.each do |p|
      @scenarios << p.scenario if not @scenarios.include? p.scenario
    end
  end

end
