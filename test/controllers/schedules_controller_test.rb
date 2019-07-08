require 'test_helper'

class SchedulesControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  
  setup do
    @schedule = schedules(:two)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:schedules)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create schedule" do
    assert_difference('Schedule.count') do
      post :create, schedule: { end_time: @schedule.end_time, scenario: @schedule.scenario, scenario_location: @schedule.scenario_location, start_time: @schedule.start_time, user_id: @schedule.user_id }
    end

    assert_redirected_to schedule_path(assigns(:schedule))
  end

  test "should show schedule" do
    get :show, id: @schedule
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @schedule
    assert_response :success
  end

  test "should update schedule" do
    patch :update, id: @schedule, schedule: { end_time: @schedule.end_time, scenario: @schedule.scenario, scenario_location: @schedule.scenario_location, start_time: @schedule.start_time, user_id: @schedule.user_id }
    assert_redirected_to schedule_path(assigns(:schedule))
  end

  test "should destroy schedule" do
    assert_difference('Schedule.count', -1) do
      delete :destroy, id: @schedule
    end

    assert_redirected_to schedules_path
  end
end
