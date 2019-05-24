Edurange::Application.routes.draw do

  resources :schedules
  #Static tutorial routes
  get 'tutorials/index'
  get 'tutorials/making_scenarios'
  get 'tutorials/student_manual'
  get 'tutorials/instructor_manual'
  get 'tutorials/quick_start_guide'
  get 'tutorials/instr_ssh_inception'

  get 'tutorials/ssh_inception'
  get 'tutorials/total_recon'

  get 'management/clean'
  get 'management/status'
  get 'management/purge'

  resources :instance_groups
  resources :players
  resources :groups do
    resources :variables, only: [:index, :new, :create]
  end
  resources :instance_roles
  resources :roles
  resources :instances
  resources :subnets
  resources :clouds
  resources :tutorials

  namespace 'analytics' do
    resources :commands, only: [:index]
  end

  resources :scenarios do
    member do
      post 'destroyme'

      post 'boot'
      post 'boot_cloud'
      post 'boot_subnet'
      post 'boot_instance'
      post 'unboot'
      post 'unboot_cloud'
      post 'unboot_subnet'
      post 'unboot_instance'
      post 'status'
      post 'pause'
      post 'start'

      post 'log_get'
      post 'clone'
      post 'clone_new'
      get  'clone_set'
      post 'save'
      post 'save_as'
      post 'obliterate_custom'

      post 'instructions_get'
      post 'instructions_modify'
      post 'instructions_student_get'
      post 'instructions_student_modify'

      post 'cloud_add'
      post 'cloud_delete'
      post 'cloud_modify'

      post 'subnet_add'
      post 'subnet_delete'
      post 'subnet_modify'

      post 'instance_add'
      post 'instance_bash_history'
      post 'instance_chef_error'
      post 'instance_delete'
      post 'instance_modify'
      post 'instance_role_add'
      post 'instance_role_remove'
      post 'instance_dynamic_ip_roll'

      post 'group_add'
      post 'group_modify'
      post 'group_delete'

      post 'group_instructions_get'
      post 'group_instructions_modify'

      post 'group_player_add'
      post 'group_player_delete'
      post 'group_student_group_add'
      post 'group_student_group_remove'

      post 'group_admin_access_add'
      post 'group_admin_access_remove'
      post 'group_user_access_add'
      post 'group_user_access_remove'

      post 'role_add'
      post 'role_delete'
      post 'role_modify'
      post 'role_package_add'
      post 'role_package_remove'
      post 'role_recipe_add'
      post 'role_recipe_remove'

      post 'recipe_view'
      post 'recipe_update_view'
      post 'recipe_global_get'
      post 'recipe_global_add'
      post 'recipe_custom_add'
      post 'recipe_remove'
      post 'recipe_update'

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

    end
  end

  post 'scenarios/create_custom'
  post 'scenarios/obliterate_custom'
  get 'scenarios/destroy/:id', to: 'scenarios#destroy'

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

  get 'student', to: 'student#index'
  get 'student/:id', to: 'student#show'
  post 'student/:id/answer_string', to: 'student#answer_string', as: 'answer_string_student'
  post 'student/:id/answer_number', to: 'student#answer_number', as: 'answer_number_student'
  post 'student/:id/answer_essay', to: 'student#answer_essay', as: 'answer_essay_student'
  post 'student/:id/answer_essay_delete', to: 'student#answer_essay_delete', as: 'answer_essay_delete_student'
  post 'student/:id/answer_essay_show', to: 'student#answer_essay_show', as: 'answer_essay_show_student'
  post 'student/:id/answer_comment_show', to: 'student#answer_comment_show', as: 'answer_comment_show_student'

  root :to => "home#index"
  devise_for :users, :controllers => {:registrations => "registrations"}
  resources :users
end
