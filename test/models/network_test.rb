require 'test_helper'

class NetworkTest < ActiveSupport::TestCase

  test 'cidr within cloud' do
    skip("removed all cloud/subnet stuff.")
    instructor = users(:instructor1)
    scenario = instructor.scenarios.new(location: :test, name: 'network_test')
    scenario.save
    assert scenario.valid?, scenario.errors.messages

    # valid cloud
    cloud = scenario.clouds.new(name: "cloud1", cidr_block: "10.0.0.0/16")
    cloud.save
    assert cloud.valid?, cloud.errors.messages

    # aws does not allow clouds to be larger than /16 or smaller than /28
    cloud.update cidr_block: "10.0.0.0/15"
    assert_not cloud.valid?, cloud.errors.messages
    assert_equal cloud.errors.keys, [:cidr_block]
    cloud.errors.clear

    cloud.update cidr_block: "10.0.0.0/29"
    assert_not cloud.valid?, cloud.errors.messages
    assert_equal cloud.errors.keys, [:cidr_block]
    cloud.errors.clear

    cloud.update cidr_block: "10.0.0.0/28"
    assert cloud.valid?, cloud.errors.messages
    assert_equal cloud.errors.keys, []

    cloud.update cidr_block: "10.0.0.0/16"
    assert cloud.valid?, cloud.errors.messages
    assert_equal cloud.errors.keys, []

    ## SUBNETS

    # subnets cidr must be within or equal to clouds cidr
    subnet1 = cloud.subnets.new(name: "subnet1", cidr_block: "10.0.0.0/16")
    subnet1.save
    assert subnet1.valid?, subnet1.errors.messages

    # above
    subnet1.update cidr_block: "10.1.0.0/16"
    assert_not subnet1.valid?, subnet1.errors.messages
    assert_equal subnet1.errors.keys, [:cidr_block]
    subnet1.errors.clear

    # below
    subnet1.update cidr_block: "9.0.0.0/16"
    assert_not subnet1.valid?, subnet1.errors.messages
    assert_equal subnet1.errors.keys, [:cidr_block]
    subnet1.errors.clear

    # within
    subnet1.update cidr_block: "10.0.1.0/24"
    assert subnet1.valid?, subnet1.errors.messages
    assert_equal subnet1.errors.keys, []

    # subnets should not overlap
    subnet2 = cloud.subnets.new(name: "subnet2", cidr_block: "10.0.2.0/24")
    subnet2.save
    assert subnet2.valid?, subnet2.errors.messages

    # overlapping with subnet1
    subnet2.update cidr_block: "10.0.1.0/25"
    assert_not subnet2.valid?, subnet2.errors.messages
    assert_equal subnet2.errors.keys, [:cidr_block]
    subnet2.errors.clear

    subnet2.update cidr_block: "10.0.2.0/24"
    assert subnet2.valid?, subnet2.errors.messages
    assert_equal subnet2.errors.keys, []

    ## INSTANCES

    # instance should be within subnet
    instance1 = subnet1.instances.new(name: "instance1", ip_address: "10.0.1.4", os: 'nat')
    instance1.save
    assert instance1.valid?, instance1.errors.messages

    # .0-.3 are reserved
    instance1.update ip_address: "10.0.1.0"
    assert_not instance1.valid?, instance1.errors.messages
    assert_equal instance1.errors.keys, [:ip_address]
    instance1.errors.clear

    instance1.update ip_address: "10.0.1.1"
    assert_not instance1.valid?, instance1.errors.messages
    assert_equal instance1.errors.keys, [:ip_address]
    instance1.errors.clear

    instance1.update ip_address: "10.0.1.2"
    assert_not instance1.valid?, instance1.errors.messages
    assert_equal instance1.errors.keys, [:ip_address]
    instance1.errors.clear

    instance1.update ip_address: "10.0.1.3"
    assert_not instance1.valid?, instance1.errors.messages
    assert_equal instance1.errors.keys, [:ip_address]
    instance1.errors.clear

    # below
    instance1.update ip_address: "10.0.0.255"
    assert_not instance1.valid?, instance1.errors.messages
    assert_equal instance1.errors.keys, [:ip_address]
    instance1.errors.clear

    # above
    instance1.update ip_address: "10.0.2.4"
    assert_not instance1.valid?, instance1.errors.messages
    assert_equal instance1.errors.keys, [:ip_address]
    instance1.errors.clear

    # correct
    instance1.update ip_address: "10.0.1.4"
    assert instance1.valid?, instance1.errors.messages
    assert_equal instance1.errors.keys, []
    instance1.errors.clear

  end

end
