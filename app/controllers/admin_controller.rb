class AdminController < ApplicationController
  before_action :authenticate_admin!

  def index
    @instructors = User.instructors
    @students = User.students

    # Mark for refactoring
    begin
      @aws_vpc_cnt = AWS::EC2.new.vpcs.count
      @aws_instance_cnt = AWS::EC2.new.instances.count
      @aws_s3_bucket = "edurange-#{AWS::IAM::Client.new.get_user.user.user_name}"
    rescue => e
      @aws_vpc_cnt = nil
      @aws_instance_cnt = nil
    end
  end

  # Creates a new instuctor.
  def instructor_create
    new_instructor_params = params.permit(:email, :name, :organization)
    @user = User.new_instructor(new_instructor_params)

    if @user.valid?
      @user.save
      @user.email_credentials(@user.password)
    else
      logger.warn("could not create instructor: #{@user.errors.messages}")
    end

    respond_to do |format|
      format.js { render 'admin/js/instructor_create.js.erb', :layout => false }
    end
  end

  # Reset a user's password
  def reset_password
    @user = User.find(params[:id])
    password = SecureRandom.hex[0..15]
    @user.password = password
    @user.save

    if not @user.errors.any?
      @user.email_credentials(password)
    end

    respond_to do |format|
      format.js { render 'admin/js/reset_password.js.erb', :layout => false }
    end
  end

  # Delete a user
  def user_delete
    @users = [*User.find(params[:id])]

    @users.each do |user|
      user.destroy unless user.id == current_user.id
    end

    respond_to do |format|
      format.js { render 'admin/js/user_delete.js.erb', :layout => false }
    end
  end

  # Promote a student to an instructor
  def student_to_instructor
    if @user = User.find(params[:id])
      if not @user.is_student?
        @user.errors.add(:email, "User is not a student")
      else
        @user.student_to_instructor
      end
    end

    respond_to do |format|
      format.js { render 'admin/js/student_to_instructor.js.erb', :layout => false }
    end
  end

  # Add all students to a group
  def student_add_to_all
    users_to_add = User.find(params[:id])
    added_users  = current_user.student_group_all.add_users(users_to_add)

    respond_to do |format|
      format.js { render 'student_groups/js/add_users.js.erb', :layout => false, locals: { student_group: current_user.student_group_all, added_users: added_users } }
    end
  end


  # Demote an instructor to a student
  def instructor_to_student
    if user = User.find(params[:id])
      if not user.is_instructor?
        user.errors.add(:email, "User is not an instructor")
      else
        user.instructor_to_student(current_user)
      end
    end

    respond_to do |format|
      format.js {
        render 'admin/js/instructor_to_student.js.erb', :layout => false , locals: {
          student_group: current_user.student_group_all,
          user: user
        }
      }
    end
  end

end
