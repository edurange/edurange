class CreateAdminService
  def call
	  user = nil
    if not user = User.find_by_email(Rails.application.secrets.admin_email)
      user = User.new(email: Rails.application.secrets.admin_email, name: Rails.application.secrets.admin_name)
    end
    user.password = Rails.application.secrets.admin_password
    user.password_confirmation = Rails.application.secrets.admin_password
    user.set_admin_role
    user
  end
end
