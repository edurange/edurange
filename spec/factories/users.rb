# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Internet.user_name(nil, %w(_)) }
    password "Password123"

    factory :admin do
      role :admin
    end
    factory :instructor do
      role :instructor
    end
    factory :student do
      role :student
    end
  end
end
