# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :role do
    name { Faker::Name.first_name }  # Roles named after people? Why not?

    scenario do
      if Scenario.count > 1
        Scenario.first
      else
        create(:scenario)
      end
    end
  end
end
