require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test 'should not save user without email, name, & password' do
    user = User.new
    user.save
    assert_not user.valid?
    expected = [:email, :password, :name]
    assert expected & user.errors.keys == expected
  end

  test 'should not save user with unallowed name' do
    user = users(:test1)

    user.name = ""
    assert_not user.valid?
    assert_equal [:name], user.errors.keys

    user.name = "   "
    assert_not user.valid?
    assert_equal [:name], user.errors.keys

    user.name = "abs$$$$"
    assert_not user.valid?
    assert_equal [:name], user.errors.keys

    user.name = "foo_bar"
    assert user.valid?
    assert_equal [], user.errors.keys
  end

  test 'should have default student role' do
    user = User.new(name: "foo", email: "foo@edurange.org", password: "nothing8", invitee_registration_code: users(:admin1).registration_code)
    assert user.valid?
    assert user.student?
  end

  test 'should not allow name update while scenario is running' do
    user = users(:instructor1)

    scenario = user.scenarios.new(location: :test, name: 'test1')
    scenario.save
    assert scenario.valid?

    scenario.set_booted
    user.name = "testchange"
    user.save
    assert_equal [:running], user.errors.keys

    scenario.set_stopped
    user.name = "testchange"
    user.save
    assert_equal [], user.errors.keys

    scenario.set_booting
    user.name = "testchange"
    user.save
    assert_equal [:running], user.errors.keys

    [:paused, :pausing, :starting, :queued_boot, 
      :queued_unboot, :booting, :booted, :failure, :boot_failed, 
      :unboot_failed, :unbooting, :stopping, :partially_booted, 
      :partially_booted_with_failure, :partially_unbooted, 
      :partially_unbooted_with_failure].each do |status|
        scenario.status = status
        scenario.save

        user.name = "testchange"
        user.save
        assert_not user.valid?
        assert_equal [:running], user.errors.keys
    end
  end

  test 'should email credentials' do 
    user = users(:test1)
    email = user.email_credentials('thisisnewpass')
    assert_not ActionMailer::Base.deliveries.empty?
  end

  test 'should set correct roles' do 
    user = users(:test1)
    user.set_student_role
    assert_match("student", user.role)
    assert user.is_student?
    assert_not user.is_instructor?
    assert_not user.is_admin?

    user.set_instructor_role
    assert_match("instructor", user.role)
    assert_not user.is_student?
    assert user.is_instructor?
    assert_not user.is_admin?

    user.set_admin_role
    assert_match("admin", user.role)
    assert_not user.is_student?
    assert_not user.is_instructor?
    assert user.is_admin?
  end

  test 'should have student group user if instructor or admin' do
    user = users(:instructor1)
    student = users(:student1)
    scenario = user.scenarios.new(location: :test, name: 'test1')

    # test instructor role
    user.set_instructor_role

    # make sure the user has student group named All
    assert user.student_groups.size == 1
    allsg = user.student_groups.find_by_name("All")
    assert allsg.valid?

    sgu = allsg.student_group_users.new(user_id: student.id)
    sgu.save
    assert sgu.valid?

    assert allsg.student_group_users.size == 1
    assert allsg.student_group_users.find_by_user_id(student.id).valid?
    
    # make sure user can not become student with a scenario that is running
    assert scenario.valid?
    assert scenario.user_id = user.id

    user.reload
    assert user.owns? scenario

    assert user.validate_running
    scenario.set_booted

    user.reload

    user.set_student_role
    assert_equal [:running], user.errors.keys
    user.errors.clear

    scenario.set_stopped
    scenario.reload
    user.reload

    # make sure when user becomes student they have no student groups or student group users
    user.set_student_role
    assert_equal [], user.errors.keys

    assert_not user.student_groups.any?
    assert_not user.student_group_users.any?

    # Do the same tests for admin
    user.reload
    scenario.reload
    user.set_admin_role

    # make sure the user has student group named All
    assert user.student_groups.size > 0
    allsg = user.student_groups.find_by_name("All")
    allsg.save
    assert allsg.valid?

    sgu = allsg.student_group_users.new(user_id: student.id)
    sgu.save
    assert sgu.valid?

    assert allsg.student_group_users.size == 1
    assert allsg.student_group_users.find_by_user_id(student.id).valid?
    
    # make sure user can not become student with a scenario that is running
    scenario.user_id = user.id
    scenario.save
    assert scenario.valid?
    assert scenario.user_id = user.id

    user.reload
    assert user.owns? scenario

    assert user.validate_running
    scenario.set_booted

    user.reload

    user.set_student_role
    assert_equal [:running], user.errors.keys
    user.errors.clear

    scenario.set_stopped
    scenario.reload
    user.reload

    # make sure when user becomes student they have no student groups or student group users
    user.set_student_role
    assert_equal [], user.errors.keys

    assert_not user.student_groups.any?
    assert_not user.student_group_users.any?
  end

  test 'after user destroy student groups and student groups users should be destroyed' do
    user = users(:test1)
    student = users(:student1)
    student2 = users(:student2)

    # make user instructor
    user.set_instructor_role

    # add student to users student group "All"
    sgu = user.student_groups.find_by_name("All").student_group_users.new(user_id: student.id)
    sgu.save
    assert sgu.valid?

    # destroy user and make sure their student group user is destroyed as well
    student.destroy
    assert_not StudentGroupUser.find_by_id(sgu.id)

    # add second student to group all. destroy user and make sure student groups and student group users are destroyed
    sg = user.student_groups.find_by_name("All")
    sgu2 = user.student_groups.find_by_name("All").student_group_users.new(user_id: student2.id)
    sgu2.save
    assert sgu2.valid?

    user.destroy

    assert_not StudentGroup.find_by_id(sg.id)
    assert_not StudentGroupUser.find_by_id(sgu2.id)
  end

  test 'should own all resources belonging to scenario and student groups' do
    user = users(:test1)
    user.set_admin_role

    # test ownership of student groups
    sg = user.student_groups.new(name: 'test')
    sg.save
    assert sg.valid?

    user.student_groups.each do |sg|
      assert user.owns? sg
    end

    # test ownership of scenario and its resources
    scenario = user.scenarios.new(location: :production, name: 'strace')
    scenario.save
    assert user.owns? scenario

    scenario.clouds.each do |cloud|
      assert user.owns? cloud
      
      cloud.subnets.each do |subnet|
        assert user.owns? subnet

        subnet.instances.each do |instance|
          assert user.owns? instance
          instance.instance_roles.each { |ir| assert user.owns? ir } 
          instance.instance_groups.each { |ig| assert user.owns? ig }

          instance.roles.each do |role|
            assert user.owns? role
            role.role_recipes.each { |rr| assert user.owns? rr }

          end
        end
      end 
    end
    scenario.recipes.each { |r| assert user.owns? r }
  end


end
