Edurange::Application.routes.draw do

  resources :schedules

  namespace 'tutorials' do
    get '/' => redirect('tutorials/introduction')
    get 'introduction'
    get 'using_edurange'
    get 'student_manual'
    get 'instructor_manual'
  end

  resources :student_groups do
    collection do
      post 'users', action: 'add_or_remove_users'
    end
    # member do
    #   post 'users', action: 'add_or_remove_users'
    # end
  end

  resources :commands, only: [:index]

  resources :scenarios do
    resources :commands, only: [:index], controller: 'scenario_commands'

    member do
      post 'start'
      post 'stop'
      post 'restart'
      post 'archive'
      post 'unarchive'

      get  'players'

      post 'group_player_add'
      post 'group_player_delete'
      post 'group_student_group_add'
      post 'group_student_group_remove'

      get  'scoring'

      post 'scoring_question_add'
      post 'scoring_question_delete'
      post 'scoring_question_modify'
      post 'scoring_question_move_up'
      post 'scoring_question_move_down'

      post 'scoring_answers_show'
      post 'scoring_answer_essay_show'
      post 'scoring_answer_essay_grade'
      post 'scoring_answer_essay_grade_edit'
      post 'scoring_answer_essay_grade_delete'
      post 'scoring_answer_comment'
      post 'scoring_answer_comment_show'
      post 'scoring_answer_comment_edit'
      post 'scoring_answer_comment_edit_show'

      get 'instances'

      get 'guide'
      get 'solution'
    end
  end

  get  'admin', to: 'admin#index'
  post 'admin/user_delete'
  post 'admin/instructor_create'
  post 'admin/student_to_instructor'
  post 'admin/student_add_to_all'
  post 'admin/instructor_to_student'
  post 'admin/reset_password'
  post 'admin/student_group_create'
  post 'admin/student_group_destroy'
  post 'admin/student_group_user_add'
  post 'admin/student_group_user_remove'

  get 'instructor', to: 'instructor#index'
  post 'instructor/student_group_create'
  post 'instructor/student_group_destroy'
  post 'instructor/student_group_user_add'
  post 'instructor/student_group_user_remove'

  get 'student', to: 'student#show'
  get 'student/scenarios/:scenario_id', to: 'student_scenarios#show', as: 'student_scenario'
  get 'student/scenarios/:scenario_id/guide', to: 'student_scenarios#show_scenario_guide', as: 'student_scenario_guide'
  get 'student/scenarios/:scenario_id/commands', to: 'student_scenario_commands#index', as: 'student_scenario_commands'

  post 'student/scenarios/:scenario_id/answer_string', to: 'student_scenarios#answer_string', as: 'answer_string_student'
  post 'student/:scenario_id/answer_number', to: 'student_scenarios#answer_number', as: 'answer_number_student'
  post 'student/:scenario_id/answer_essay', to: 'student_scenarios#answer_essay', as: 'answer_essay_student'
  post 'student/:scenario_id/answer_essay_delete', to: 'student_scenarios#answer_essay_delete', as: 'answer_essay_delete_student'
  post 'student/:scenario_id/answer_essay_show', to: 'student_scenarios#answer_essay_show', as: 'answer_essay_show_student'
  post 'student/:scenario_id/answer_comment_show', to: 'student_scenarios#answer_comment_show', as: 'answer_comment_show_student'

  root :to => "home#index"
  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users
end
