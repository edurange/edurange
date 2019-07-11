class CreateAdminService
  def call
    User.create!(
      email: Rails.application.secrets.admin_email,
      name: Rails.application.secrets.admin_name,
      password: Rails.application.secrets.admin_password,
      role: 'admin'
    )
  end
end
