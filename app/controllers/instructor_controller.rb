class InstructorController < ApplicationController
  before_action :authenticate_instructor!
  before_action :set_student_group, only: [:student_group_destroy]

  def index
    @players = Player.where(user_id: current_user.id)
  end

  def student_group_create
    @student_group = current_user.student_groups.new(name: params[:name])
    @student_group.save

    respond_to do |format|
      format.js { render 'instructor/js/student_group_create.js.erb', :layout => false }
    end
  end

  def student_group_destroy
    @student_group.destroy
    respond_to do |format|
      format.js { render 'instructor/js/student_group_delete.js.erb', :layout => false }
    end
  end

  def student_group_user_add
    users = User.find(params[:user_id])

    if @student_group = @user.student_groups.find_by_name(params[:student_group_name])
      @student_group_users = @student_group.user_add(users)
    end

    respond_to do |format|
      format.js { render 'instructor/js/student_group_user_add.js.erb', :layout => false }
    end
  end

  def student_group_user_remove
    @student_group_users = StudentGroupUser.find(params[:student_group_user_id])

    # student_group_user_id may or may not contain multiple ids
    if not @student_group_users.respond_to? "each"
      @student_group_users = [@student_group_users]
    end

    @student_group_users.each do |sgu|
      if sgu.student_group.user == User.find(current_user.id)
        sgu.destroy
      end
    end

    respond_to do |format|
      format.js { render 'instructor/js/student_group_user_remove.js.erb', :layout => false }
    end
  end

  private

  def set_student_group
    @student_group = StudentGroup.find(params[:student_group_id])
    if not User.find(current_user.id).owns? @student_group
      head :ok, content_type: "text/html"
      return
    end
  end

end
