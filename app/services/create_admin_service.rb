class CreateAdminService
  def call
    User.create!(
      email: Rails.application.secrets.admin_email,
      name: Rails.application.secrets.admin_name,
      password: Rails.application.secrets.admin_password,
      role: 'admin',
      registration_code: User.generate_registration_code,
      student_groups: [StudentGroup.new(name: 'All')]
    )
  end
end
