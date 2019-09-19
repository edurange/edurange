# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :subnet do
    name "MyString"
    cidr_block "MyString"
    driver_id "MyString"
    internet_accessible ""
    cloud nil
  end
end
