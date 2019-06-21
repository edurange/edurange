class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def not_authorized
    flash[:alert] = "Access denied."
    redirect_to (request.referrer || root_path)
  end

  def authenticate_role!(*roles)
    authenticate_user!
    not_authorized unless roles.include? current_user.role
  end

  User.roles.each do |role_name, _|
    define_method "authenticate_#{role_name}!" do
      authenticate_role! role_name
    end
  end

  def authenticate_admin_or_instructor!
    authenticate_role!('admin', 'instructor')
  end

end
