require 'test_helper'

def create_scenario(user, location, name)
  scenario = user.scenarios.new(location: location, name: name)
  scenario.save
  assert scenario.valid?, scenario.errors.messages
  assert_equal scenario.errors.keys, []
  scenario
end

def wait_for_delayed_jobs_to_finish
  wait_time = 30
  while Delayed::Job.all.any?
    break if wait_time == 0
    sleep 1
    wait_time -= 1
  end
  if wait_time == 0
    assert false, "Delayed Jobs for Scenairo stalled #{Delayed::Job.all.pluck(:queue).to_s}:\n#{scenario.log}"
  end
end

def valid_statuses?(resources)
  resources.select { |k,v|  v[:class] != "Cloud" }.each do |k,v|
    return false if v[:status] == :booted and resources[v[:parent]][:status] == :stopped
  end
  true
end

def boot_valid?(resources)
  outcome = {}

  return false if resources.select { |r, v| v[:action] == :none }.size == resources.size

  resources.each do |resource, value|

    outcome[resource] = {}
    outcome[resource][:class] = value[:class]
    outcome[resource][:parent] = value[:parent]
    outcome[resource][:status] = value[:status]

    if value[:action] == :boot or value[:action] == :boot_fail
      return false if value[:status] == :booted
      outcome[resource][:status] = :booted
    elsif value[:action] == :unboot or value[:action] == :unboot_fail
      return false if value[:status] == :stopped
      outcome[resource][:status] = :stopped
    end
  end
  
  valid_statuses?(outcome)
end

def boot_outcome(resources, scenario_name)

  outcome = {}
  resources.each { |r,v| outcome[r] = v[:status].to_s }

  resources.select { |r,v| v[:class] == "Cloud" }.each do |r, v|
    if resources[r][:action] == :boot
      outcome[r] = "booted"
    end
  end

  resources.select { |r,v| v[:class] == "Subnet" }.each do |r, v|
    if resources[r][:action] == :boot and outcome[resources[r][:parent]] == "booted"
      outcome[r] = "booted"
    end
  end

  resources.select { |r,v| v[:class] == "Instance" }.each do |r, v|
    if resources[r][:action] == :boot and outcome[resources[r][:parent]] == "booted"
      outcome[r] = "booted"
    end
    if resources[r][:action] == :unboot
      outcome[r] = "stopped"
    end
  end

  resources.select { |r,v| v[:class] == "Subnet" }.each do |r, v|
    if resources[r][:action] == :unboot and not resources[r][:children].select { |k| outcome[k] == "booted" }.any?
      outcome[r] = "stopped"
    end
  end

  resources.select { |r,v| v[:class] == "Cloud" }.each do |r, v|
    if resources[r][:action] == :unboot and not resources[r][:children].select { |k| outcome[k] == "booted" }.any?
      outcome[r] = "stopped"
    end
  end

  size = resources.size
  if outcome.select { |k,v| v == "stopped" }.size == size
    outcome[scenario_name] = "stopped"
  elsif outcome.select { |k,v| v == "booted" }.size == size
    outcome[scenario_name] = "booted"
  else
    outcome[scenario_name] = "booted_partial"
  end

  return outcome
end

def test_delayed_jobs
  # make sure delayed jobs is running
  u = users('test1')
  u.save
  assert u.valid?
  assert_equal u.name, "test1"

  dj = u.delay(queue: "scenario").update_attribute(:name, 'change')

  n = 0
  until (u.name == 'change' or n > 10) do
    sleep 1
    n += 1
    u.reload
  end

  Delayed::Job.destroy_all
  assert_equal 'change', u.name, "delayed jobs must be running in test environment"
end

def test_all(scenario, min, max, background, console_print, log_print)

  resources = scenario.descendents_status_relations
  resources.each { |r,v| v[:action] = :none }
  options = {}
  scenario.descendents.each { |d| options[d.name] = {} }

  statuses_list = [:stopped, :booted]
  actions_list = [:none, :boot, :boot_fail, :unboot, :unboot_fail]

  size = resources.size
  cnt = 0

  ((2**size) * (5**size)).times do |n|

    next if (n < min or n > max) and (min != -1 and max != -1)
    # next if n < 55

    # set statuses and actions
    statuses =(n % 2**size).to_s(2).rjust(size, '0')
    actions = (n % 5**size).to_s(5).rjust(size, '0')
    resources.each_with_index do |(k,v), i| 
      v[:status] = statuses_list[statuses[i].to_i]
      v[:action] = actions_list[actions[i].to_i]
    end

    # check for invalid status configurations
    next if not valid_statuses?(resources)

    # get if valid options or not
    valid = boot_valid?(resources)
    next if not valid

    # puts resources
    # cnt += 1
    # next

    # create options
    options = {}
    resources.each do |r,v| 
      options[r] = {}
      if v[:action] == :boot_fail
        options[r][:action] = :boot
      elsif v[:action] == :unboot_fail
        options[r][:action] = :unboot
      else
        options[r][:action] = v[:action]
      end
      options[r][:fail] = (v[:action] == :boot_fail or v[:action] == :unboot_fail) ? true : false
      options[r][:background] = background
      options[r][:pretend] = true
      options[r][:wait] = Random.rand
    end
    options[:console_print] = console_print

    # set scenario status and reset boot code
    scenario.descendents.each { |d| d.update_attribute(:status, resources[d.name][:status]); d.update_attribute(:boot_code, "")  }
    scenario.update_attribute(:boot_code, "")
    scenario.status_update

    # get starting 
    start = scenario.resources_status_hash

    # make expecting
    puts "n: #{n}/#{(2**size) * (5**size)}" 
    scenario.boot(options.deep_dup)

    # expect errors from those with fail in them
    puts scenario.log if log_print
    if options.select { |k, v| k.class == String and v[:fail] == true }.any?
      assert scenario.errors.any? 
      puts "err: #{scenario.errors.messages}\n\n" if console_print
      scenario.errors.clear
    else
      assert_not scenario.errors.any?
      puts "" if console_print
    end
    scenario.clear_log

    # expected outcome should be equal to actual
    outcome = boot_outcome(resources, scenario.name)
    assert_equal outcome, scenario.resources_status_hash

    cnt += 1
  end
  puts "cnt: #{cnt}"
end

class BootTest < ActiveSupport::TestCase

  self.use_transactional_tests = false

  # test 'schedule fail' do

  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_2')

  #   options = { resources: {} }
  #   scenario.descendents.each do |r|
  #     options[:resources][r.name] = {}
  #     options[:resources][r.name][:action] = :boot
  #     options[:resources][r.name][:background] = true
  #     options[:resources][r.name][:pretend] = false
  #   end
  #   # options[:console_print] = true

  #   puts "Booting Start"
  #   t1 = Time.now
  #   log  = scenario.boot(options)
  #   scenario.reload
  #   puts "Booting Finished time: #{((Time.now - t1)/60).round(2)}m"
  #   puts log

  #   scenario.descendents.each do |r|
  #     options[:resources][r.name][:action] = :unboot
  #   end
  #   options.delete(:boot_code)
  #   options.delete(:timeout)

  #   # puts "Enter to Unboot"
  #   # STDIN.gets 
  #   puts "Press [enter] to unboot"
  #   t1 = Time.now
  #   log = scenario.boot(options)
  #   puts "Unbooting Finished time: #{((Time.now - t1)/60).round(2)}m"
  #   puts log

  # end

  # test 'scenairo creation and destruction' do
  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_3')
  #   puts "Booting"
  #   scenario.boot_all(false, false, true)

  #   puts "Waiting for Instance to initialize"
  #   while not scenario.instances_initialized?
  #     sleep 1
  #     scenario.reload
  #   end
  #   puts "Instances initialized"

  #   bash_history = scenario.instances.first.get_bash_history
  #   puts "Bash History\n#{bash_history}"

  #   # puts "Press [enter] to unboot"
  #   # STDIN.gets

  #   puts "Unbooting"
  #   scenario.unboot_all(false, false, true)

  #   scenario.destroy

  # end

  # test 'boot code' do
  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_3')

  #   cloud = scenario.clouds.first

  #   cloud.update_attribute(:boot_code, 'sup')
  #   cloud.boot_single(:boot, true, false, false)
  #   assert_equal cloud.status, "stopped"

  #   cloud.update_attribute(:boot_code, '')
  #   cloud.boot_single(:boot, true, false, false)
  #   assert_equal cloud.status, "booted"
  # end

  # test 'single boot' do
  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_3')

  #   scenario.subnets.first.boot_single(:boot, true, false, false)
  #   assert scenario.subnets.first.stopped?, scenario.subnets.first.status

  #   scenario.instances.first.boot_single(:boot, true, false, false)
  #   assert scenario.instances.first.stopped?, scenario.instances.first.status

  #   scenario.clouds.first.boot_single(:boot, true, false, false)
  #   assert scenario.clouds.first.booted?, scenario.clouds.first.status

  #   scenario.instances.first.boot_single(:boot, true, false, false)
  #   assert scenario.instances.first.stopped?, scenario.instances.first.status

  #   scenario.subnets.first.boot_single(:boot, true, false, false)
  #   assert scenario.subnets.first.booted?, scenario.subnets.first.status

  #   scenario.instances.first.boot_single(:boot, true, false, false)
  #   assert scenario.instances.first.booted?, scenario.instances.first.status

  # end

  # test 'docker boot' do
  #   return if Rails.configuration.x.provider != 'docker'
  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_4')
  #   scenario.boot_all(false, false, true)
  # end

  # test 'provider test' do
  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_5')

  #   # fail if driver id is set
  #   scenario.clouds.first.update_attribute(:driver_id, 'foo')
  #   scenario.boot_all(pretend: false, console_print: true)
  #   assert scenario.errors.any?

  #   # make sure all descendents are released
  #   assert scenario.descendents.select { |d| d.boot_code != ''}.size == 0

  # end

  # test 'resource deletes in middle of boot' do
  #   return
  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_5')

  #   # delete parent during boot
  #   scenario.boot(pretend: true, resources: {
  #       "Cloud1" => {
  #         wait: 10
  #       }
  #     }
  #   )

  #   # delete child during unboot
  # end

  # test 'test 5' do
  #   25.times do |n|
  #     scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_5')

  #     puts "Booting #{n}"
  #     if not scenario.boot(background: true, console_print: false)
  #       puts scenario.log_last
  #       assert false, "Boot failed"
  #     end

  #     puts "Unbooting #{n}"
  #     if not scenario.unboot(background: true, console_print: false)
  #       puts scenario.log_last
  #       assert false, "Unboot failed"
  #     end
  #   end
  # end

  # test 'aws test' do

  #   return

  #   scenario = create_scenario(users(:instructor999999999), :test, 'Boot_Test_5')

  #   cloud = scenario.clouds.first
  #   subnet = scenario.subnets.first
  #   instance = scenario.instances.first

  #   cloud.boot(pretend: true)
  #   puts cloud.errors.messages
  #   # assert_not cloud.errors.any?

  #   return

  #   subnet.boot
  #   assert_not subnet.errors.any?

  #   instance.boot
  #   assert_not instance.errors.any?

  #   # instance.unboot
  #   # assert_not instance.errors.any?

  #   subnet.unboot
  #   assert_not subnet.errors.any?

  #   cloud.unboot
  #   assert_not cloud.errors.any?

  #   return

  #   # boot Cloud save driver for later
  #   cloud = scenario.clouds.first
  #   cloud.boot
  #   assert_not cloud.errors.any?
  #   assert cloud.booted?
  #   cloud_driver_id = cloud.driver_id

  #   # try and boot cloud again make sure there is a boot error
  #   cloud.boot
  #   assert cloud.errors.any?
  #   cloud.errors.clear

  #   # boot subnet save driver for later
  #   subnet = cloud.subnets.first
  #   subnet.boot
  #   assert_not subnet.errors.any?
  #   assert subnet.booted?
  #   subnet_driver_id = cloud.driver_id

  #   # unboot subnet
  #   subnet.unboot
  #   assert_not subnet.errors.any?
  #   assert subnet.stopped?

  #   # try to unboot again and make sure error happens
  #   subnet.unboot
  #   assert subnet.errors.any?
  #   subnet.errors.clear

  #   # reinstate old driver id and try and unboot
  #   # this should still unboot ignoring and clearing the bad driver id
  #   subnet.update_attribute(:driver_id, subnet_driver_id)
  #   subnet.set_booted
  #   subnet.unboot
  #   assert_not subnet.errors.any?

  #   # set a bogus driver id and trya and boot
  #   # this should still unboot ignoring and clearing the bad driver id
  #   subnet.update_attribute(:driver_id, 'bogus')
  #   subnet.set_booted
  #   subnet.unboot
  #   assert_not subnet.errors.any?

  #   # unboot cloud
  #   cloud.unboot
  #   assert_not cloud.errors.any?
  #   assert cloud.stopped?

  #   # try to unboot again and make sure error happens
  #   cloud.unboot
  #   assert cloud.errors.any?
  #   cloud.errors.clear

  #   # reinstate old driver id and try and unboot
  #   # this should still unboot 
  #   cloud.update_attribute(:driver_id, cloud_driver_id)
  #   cloud.set_booted
  #   cloud.unboot
  #   assert_not cloud.errors.any?

  #   # set a bogus driver id and trya and boot
  #   cloud.update_attribute(:driver_id, 'bogus')
  #   cloud.set_booted
  #   cloud.unboot
  #   assert_not cloud.errors.any?


  #   return

  #   # boot scenario
  #   puts "Booting Scenario:"
  #   scenario.boot_all(console_print: true)
  #   assert_not scenario.errors.any?

  #   # save driver id of VPC
  #   driver_id = scenario.clouds.first.driver_id

  #   # unboot scenario
  #   puts "\nUnbooting Scenario:"
  #   scenario.unboot_all(console_print: true)
  #   assert_not scenario.errors.any?

  #   # set cloud to booted with old driver id
  #   scenario.clouds.first.update_attribute(:driver_id, driver_id)
  #   scenario.clouds.first.set_booted
  #   puts "\nUnbooting Scenario with old driver id '#{driver_id}':"

  #   # try and unboot it now with the old driver id
  #   scenario.unboot_all(console_print: true)

  #   assert scenario.stopped?, scenario.status
  #   assert scenario.clouds.first.stopped?, scenario.clouds.first.status
  #   assert_not scenario.clouds.first.driver_id, scenario.clouds.first.driver_id

  # end



end
