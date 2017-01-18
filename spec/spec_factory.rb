require 'factory_girl'
FactoryGirl.define do
  factory :player do 
    sequence(:login) { |i| "player_#{i}" }
  end
  factory :group do 
    sequence(:group_names) { |i| "group_#{i}" }
    factory :group_with_three_players do
      before(:create) do |group|
	create(:player, group: group)
	create(:player, group: group)
	create(:player, group: group)
      end
    end
  end
  factory :instance do
    os 'ubuntu'
    ip '10.0.0.4'
  end
  factory :subnet do 
    cidr_block '10.0.0.0/24'
    before(:create) do |subnet|
      subnet.instances << FactoryGirl.build(:instance, subnet: subnet)
    end
  end
  factory :monitoring_unit do 
    before(:create) do |monitoring_unit|
      monitoring_unit.subnets << FactoryGirl.build(:subnet, monitoring_unit: monitoring_unit)
    end
  end
  factory :scenario do
    game_type :recon
    name "edurange test 1"
    before(:create) do |scenario|
      scenario.monitoring_units << FactoryGirl.build(:monitoring_unit, scenario: scenario)
    end
  end
end
