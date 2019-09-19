# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :scenario do
    association :user, factory: :instructor
    name "Test1"
    location :test
  end
end
