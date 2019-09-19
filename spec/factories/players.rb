# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :player do
    login "MyString"
    password "MyString"
    group nil
  end
end
