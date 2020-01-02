require 'test_helper'

class StudentsControllerTest < ActionController::TestCase

	include Devise::TestHelpers

	def setup
		@controller = StudentController.new
	end

	test 'should redirect to home if not logged in' do
		get :show
		assert_redirected_to new_user_session_path
	end

	test 'should go to index if logged in' do
		u = users(:student1)
		s = scenarios(:two)
		g = s.groups.new(name: "foo")
		g.save
		assert g.valid?
		p = g.players.new(login: "foo", password: "pass", user_id: u.id)
		p.save

		sign_in(u)

		get :show
		assert_response :success
		assert_not_nil assigns(:scenarios)

		assert assigns(:scenarios).size == 1
		assert assigns(:scenarios)[0] == s

		# make sure links to view each scenario are here
		assigns(:scenarios).each do |scenario|
			assert_select "a[href='student/scenarios/#{scenario.id}']"
		end
	end

	test 'js' do

	end

end
