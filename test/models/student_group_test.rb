require 'test_helper'

class StudentGroupTest < ActiveSupport::TestCase

  test 'student deletion' do
    instructor = users('student_group_instructor')
    student_1 = users('student_group_user_1')
    student_2 = users('student_group_user_2')

    assert instructor.valid?

    assert instructor.student_groups.size == 2
    assert student_group_all = instructor.student_groups.find_by_name("All")
    assert student_group_other = instructor.student_groups.find_by_name("Other")

    assert student_group_all.student_group_users.size == 2
    assert student_group_all.student_group_users.find_by_user_id(student_1.id)
    assert student_group_all.student_group_users.find_by_user_id(student_2.id)
    assert student_group_other.student_group_users.find_by_user_id(student_1.id)
    assert student_group_other.student_group_users.find_by_user_id(student_2.id)

    # when student is destroyed so should all their StudentGroupUser entrie
    student_1.destroy
    assert_not student_group_all.student_group_users.find_by_user_id(student_1.id)
    assert_not student_group_other.student_group_users.find_by_user_id(student_1.id)

    # when instructor is destroyed so should all their StuentGroups and StudentGroupUsers
    instructor.destroy
    assert_not student_group_all.student_group_users.find_by_user_id(student_1.id)
    assert_not student_group_all.student_group_users.find_by_user_id(student_2.id)
    assert_not student_group_other.student_group_users.find_by_user_id(student_1.id)
    assert_not student_group_other.student_group_users.find_by_user_id(student_2.id)
    assert student_group_all.student_group_users.size == 0

    assert_not StudentGroup.find_by_id(student_group_all.id)
    assert_not StudentGroup.find_by_id(student_group_other.id)
  end
end
