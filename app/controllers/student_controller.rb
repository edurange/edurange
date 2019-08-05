class StudentController < ApplicationController
  before_action :authenticate_student!

  def show
    @scenarios = []
    Player.where(user_id: current_user.id).each do |p|
      @scenarios << p.scenario if not @scenarios.include? p.scenario
    end
  end

end
