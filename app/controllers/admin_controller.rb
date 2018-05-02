class AdminController < ApplicationController
  before_action :authenticate_admin
  before_action :set_student_group, only: [:student_group_destroy]

  def index
    @instructors = User.where role: 3
    @students = User.where role: 4
    
    # If someone knows what this AWS stuff does and can add a few comments to it that would be great
    begin
      @aws_vpc_cnt = AWS::EC2.new.vpcs.count
      @aws_instance_cnt = AWS::EC2.new.instances.count
    rescue => e
      @aws_vpc_cnt = nil
      @aws_instance_cnt = nil
    end
  end
  
  
  # Creates a new instuctor.
  def instructor_create
    name = params[:name] == '' ? nil : params[:name]
    @user = User.new(email: params[:email], name: name, organization: params[:organization])
    password = SecureRandom.hex[0..15]
    @user.password = password
    @user.save

    if not @user.errors.any?
      @user.set_instructor_role
      @user.email_credentials(password)
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
    @users = User.find(params[:id])
    @users = [@users] unless @users.respond_to? "each"

    @student_group_users = []
    @users.each do |user|
      if not user.is_student?
        user.errors.add(:email, "#{user.name} is not a student")
      else
        @student_group, student_group_user = current_user.student_add_to_all(user)
        @student_group_users.push(student_group_user)
      end
    end

    respond_to do |format|
      format.js { render 'admin/js/student_add_to_all.js.erb', :layout => false }
    end
  end


  # Demote an instructor to a student
  def instructor_to_student
    if @user = User.find(params[:id])
      if not @user.is_instructor?
        @user.errors.add(:email, "User is not a student")
      else
        @student_group, @student_group_user = @user.instructor_to_student(User.find(current_user.id))
      end
    end

    respond_to do |format|

      format.js { render 'admin/js/instructor_to_student.js.erb', :layout => false }
    end
  end

  # Create a new student group
  def student_group_create
    @user = User.find(current_user.id)
    @student_group = @user.student_groups.new(name: params[:name])
    @student_group.save

    respond_to do |format|
      format.js { render 'admin/js/student_group_create.js.erb', :layout => false }
    end
  end

  # Remove a student group
  def student_group_destroy
    @student_group.destroy
    respond_to do |format|
      format.js { render 'admin/js/student_group_delete.js.erb', :layout => false }
    end
  end

  # Add a user to a student group
  def student_group_user_add
    users = [*StudentGroupUser.find(params[:student_group_user_id])].collect{ |sgu| sgu.user }
    @student_group = @user.student_groups.find_by_name(params[:student_group_name])

    if not @student_group.nil?
      @student_group_users = @student_group.user_add(users)
    end

    respond_to do |format|
      format.js { render 'admin/js/student_group_user_add.js.erb', :layout => false }
    end
  end

  # Remove a user from a student group
  def student_group_user_remove
    @student_group_users = [*StudentGroupUser.find(params[:student_group_user_id])]

    @student_group_users.each do |student_group_user|
      if student_group_user.student_group.user.id == current_user.id
        student_group_user.destroy
      end
    end

    respond_to do |format|
      format.js { render 'admin/js/student_group_user_remove.js.erb', :layout => false }
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
