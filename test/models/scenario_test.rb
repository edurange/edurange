require 'test_helper'

class ScenarioTest < ActiveSupport::TestCase

  test 'should only allow instructor and admin to create scenario' do
    student = users(:student1)
    instructor = users(:instructor1)
    admin = users(:admin1)

    scenario = student.scenarios.new(location: :test, name: 'test1')
    scenario.save
    assert_not scenario.valid?

    assert(scenario.errors.keys.include? :user)

    scenario = instructor.scenarios.new(location: :test, name: 'test1')
    scenario.save
    assert scenario.valid?
    assert_equal [], scenario.errors.keys
  end

  test 'should rescue when yml is corrupted' do
    skip 'unlear what is supposed to be wrong about the configuration'

    scenario = Scenario.load(location: :test, name: 'badyml', user: users(:instructor1))
    assert_not(scenario.valid?)
    assert_equal(scenario.errors.keys.include(:load))

    scenario = instructor.scenarios.new(location: :test, name: 'badyml2')
    assert_not(scenario.valid?)
    assert_equal(scenario.errors.keys.include(:load))
  end

  test 'production scenarios should load' do
    instructor = users(:instructor1)
    Dir.foreach('scenarios/production') do |filename|
      next if ['.','..'].include? filename
      scenario = instructor.scenarios.new(location: :production, name: filename)
      scenario.save
      assert_equal [], scenario.errors.keys, "production scenario #{filename} does not load. #{scenario.errors.messages}"
    end
  end

  test 'ip address should be valid' do
    skip("kind of recklessly ripped out the advanced ip address stuff, should add back at some point")
    instructor = users(:instructor999999999)
    scenario = Scenario.load(location: :test, name: 'dynamicip', user: instructor)

    assert_not scenario.errors.any?, scenario.errors.messages

    instance = scenario.instances.first
    ip = instance.ip_address
    dip = instance.ip_address_dynamic

    # ip address should be assigned
    assert ip

    # ip address should be valid and within subnets ip
    assert IPAddress.valid_ipv4?(ip)
    assert NetAddr::CIDR.create(instance.subnet.cidr_block).cmp(ip)

    # assert that dynamic_ip is of class DynamicIP
    assert dip.class == DynamicIP, "ip class is #{dip.class} should be DynamicIP"
    assert_not dip.error?

    # roll for a new IP
    ip = instance.ip_address
    instance.ip_roll
    ip2 = instance.ip_address

    assert ip != ip2, "ip should not be the same after roll. #{ip} != #{ip2}"
  end

  test 'dynamic ip address' do

  end

  test 'special question values' do
    skip("unfortunately I removed ip special values")
    scenario = Scenario.load(location: :test, name: 'special_question_values', user:  users(:instructor999999999))

    assert scenario.valid?, scenario.errors.messages

    question = scenario.questions.first
    assert_equal(
      question.values.first[:value],
      scenario.instances.first.ip_address,
      "#{question.values.first[:value]} != #{scenario.instances.first.ip_address}"
    )
    assert_equal question.values.first[:special], "$Instance_1$"
    assert_equal(
      question.values.second[:value],
      scenario.instances.second.ip_address,
      "#{question.values.second[:value]} != #{scenario.instances.second.ip_address}"
    )
    assert_equal question.values.second[:special], "$Instance_2$"

  end

end
