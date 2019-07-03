class UserMailer < ApplicationMailer
    layout false

    def email_credentials(user, password)
        @user = user
        @password = password
        mail(to: user.email, subject: 'Welcome EDURange Instructor')
    end

    def reset_password(user, password)
        @user = user
        @password = password
        mail(to: user.email, subject: 'EDURange password reset')
    end

    def test_email(email)
        mail(to: email, subject: 'EDURange test')
    end

end
