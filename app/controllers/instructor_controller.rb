class InstructorController < ApplicationController
  before_action :authenticate_instructor!

  def index
    @players = Player.where(user_id: current_user.id)
  end

end
