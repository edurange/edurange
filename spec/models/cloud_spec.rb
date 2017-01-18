require 'spec_helper'

describe Cloud do
  before do
    @cloud = Cloud.new(scenario: mock_model("Scenario"), name: 'Test-Cloud', cidr_block: '10.0.0.0/16')
  end
  it 'should be valid' do
    expect(@cloud.valid?).to be true
  end
  # @cloud.scenario
  it 'should not be valid without a scenario' do
    @cloud.scenario = nil
    expect(@cloud.valid?).to be false
  end
  
  # @cloud.name
  it 'should not be valid without a name' do
    @cloud.name = nil
    expect(@cloud.valid?).to be false
  end

  # @cloud.cidr_block
  it 'should not be valid without a cidr_block' do
    @cloud.cidr_block = nil
    @cloud.valid?
    expect(@cloud).to have(1).errors_on(:cidr_block)
  end
  
  it 'should not be valid with an non-iplike cidr_block' do
    @cloud.cidr_block = 'abcd'
    @cloud.valid?
    expect(@cloud).to have(1).errors_on(:cidr_block)
  end

  it 'should not be valid with an ip address cidr_block (should be a network)' do
    @cloud.cidr_block = '10.0.0.0'
    @cloud.valid?
    expect(@cloud).to have(1).errors_on(:cidr_block)
  end
  it 'should not be valid with a very small network' do
    @cloud.cidr_block = '10.0.0.0/29'
    @cloud.valid?
    expect(@cloud).to have(1).errors_on(:cidr_block)
  end
  it 'should not be valid with a very large network' do
    @cloud.cidr_block = '10.0.0.0/15'
    @cloud.valid?
    expect(@cloud).to have(1).errors_on(:cidr_block)
  end
end
