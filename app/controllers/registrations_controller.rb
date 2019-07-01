class RegistrationsController < Devise::RegistrationsController
  before_action do
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:name, :invitee_registration_code])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def new
    super do |user|
      user.invitee_registration_code = params[:registration_code]
      user.email = params[:email]
    end
  end

  def after_sign_up_path_for(resource)
    root_path
  end

end
