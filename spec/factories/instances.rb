# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :instance do
    name "MyString"
    ip_address "MyString"
    driver_id "MyString"
    cookbook_url "MyString"
    os "MyString"
    internet_accessible ""
    subnet nil
  end
end
