require 'test_helper'

class TutorialControllerTest < ActionController::TestCase

	include Devise::TestHelpers

	def setup
		@controller = TutorialsController.new
	end

  test "should get index" do

		u = users(:student1)
		sign_in(u)

    get 'introduction'
    assert_response :success

		get 'using_edurange'
		assert_response :success

		get 'student_manual'
		assert_response :success

		get 'instructor_manual'
		assert_response :success
  end

end
