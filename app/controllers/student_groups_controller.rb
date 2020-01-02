class StudentGroupsController < ApplicationController
  before_action :authenticate_admin_or_instructor!

  def create
    @student_group = current_user.student_groups.new(name: params[:name])
    @student_group.save

    respond_to do |format|
      format.js { render 'student_groups/js/create.js.erb', :layout => false }
    end
  end

  def find_and_authorize_student_group!
    student_group = StudentGroup.find(params[:id])
    not_found if student_group.nil?
    not_authorized unless current_user.owns? student_group
    student_group
  end

  def destroy
    @student_group = find_and_authorize_student_group!
    @student_group.destroy
    respond_to do |format|
      format.js { render 'student_groups/js/destroy.js.erb', layout: false }
    end
  end

  def add_or_remove_users
    if params.has_key? :add then
      add_users
    elsif params.has_key? :remove then
      remove_users
    end
  end

  def add_users
    users = User.find(params[:user_id])
    student_group = StudentGroup.find(params[:add_to_id])
    added_users = student_group.add_users(users)
    logger.debug("added #{added_users.size} users to #{student_group.name}")
    respond_to do |format|
      format.html do
        redirect_back(
          fallback_location: '/',
          notice: "Added #{added_users.size} users to #{student_group.name}"
        )
      end
      format.js do
        render('student_groups/js/add_users.js.erb',
          layout: false,
          locals: {
            added_users:   added_users,
            student_group: student_group
          }
        )
      end
    end
  end

  def remove_users
    users = User.find(params[:user_id])
    student_group = StudentGroup.find(params[:remove_from_id])
    removed_users = student_group.remove_users(users)
    count = removed_users.size
    notice = "Removed #{count} #{count == 1 ? 'user' : 'users'} from student group #{student_group.name}"
    respond_to do |format|
      format.html do
        redirect_back(fallback_location: '/', notice: notice)
      end
      format.js do
        render('student_groups/js/remove_users.js.erb', layout: false, locals: {
          student_group: student_group,
          removed_users: removed_users
        })
      end
    end
  end

  # All this functionality should be moved to the instructor controller

  # def index
  #   # @message = params[:message]
  #   student_groups = StudentGroup.where :instructor_id => current_user.id
  #   @named_array = {}

  #   student_groups.each do |student_group|
  #     if !@named_array.key? student_group.name
  #       @named_array[student_group.name] = []
  #     end

  #     if student_group.student_id != current_user.id
  #       user = User.find(student_group.student_id)
  #       @named_array[student_group.name].push user
  #     end
  #   end
  # end

  # def new
  #   group = StudentGroup.where(
  #                             :instructor_id => current_user.id,
  #                             :name => params[:name]
  #                             )
  #   if group.blank?
  #     StudentGroup.create(
  #                         :instructor_id => current_user.id,
  #                         :name => params[:name],
  #                         :student_id => current_user.id
  #                         )
  #   else
  #     flash[:new_group_err] = "Student Group already exists"
  #   end
  #   # redirect_to instructor_groups_path :message => message
  #   redirect_to '/student_groups'
  # end

  # def destroy
  #   StudentGroup.where(
  #                     :instructor_id => current_user.id,
  #                     :name => params[:group_name]
  #                     ).destroy_all
  #   redirect_to '/student_groups'
  # end

  # def add_to
  #   user = User.find_by_email params[:email]
  #   if user and user.is_student?
  #     record = StudentGroup.where(
  #                                 :instructor_id => current_user.id,
  #                                 :name => params[:group_name],
  #                                 :student_id => user.id
  #                                 )
  #     if record.blank?
  #       StudentGroup.create(
  #                           :instructor_id => current_user.id,
  #                           :name => params[:group_name],
  #                           :student_id => user.id
  #                           )
  #     else
  #       message = "student already in group"
  #     end
  #   else
  #     # flash message
  #   end
  #   redirect_to '/student_groups'
  # end

  # def remove_from
  #   user = User.find_by_email params[:email]
  #   if user
  #     StudentGroup.where(
  #                       :instructor_id => current_user.id,
  #                       :name => params[:group_name],
  #                       :student_id => user.id
  #                       ).destroy_all
  #   end
  #   redirect_to '/student_groups'
  # end

end
