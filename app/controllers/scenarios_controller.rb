require 'dynamic_ip'

class ScenariosController < ApplicationController
  before_action :authenticate_admin_or_instructor
  before_action :set_user

  # Scenario
  before_action :set_scenario, only: [
    :clone, :destroyme, :edit, :modify, :show, :update, :save, :save_as, :log_get,
    :boot, :status, :unboot, :pause, :start,
    :cloud_add, 
    :player_modify, :player_student_group_add, :player_add, :player_group_add, :player_delete, :player_group_admin_access_add, :player_group_user_access_add,
    :role_recipe_add, :role_add,
    :recipe_custom_add, :recipe_global_add, :recipe_global_get, :recipe_remove, :recipe_update, :recipe_update_view, :recipe_view,
    :group_add, :group_instructions_get, :group_instructions_modify,
    :scoring_question_add, :scoring_answers_show, :scoring_answer_essay_show, :scoring_answer_comment, :scoring_answer_comment_show,
    :scoring_answer_comment_edit, :scoring_answer_comment_edit_show, :scoring_answer_essay_grade, :scoring_answer_essay_grade_edit,
    :scoring_answer_essay_grade_delete,
    :instructions_get, :instructions_modify, :instructions_student_get, :instructions_student_modify
  ]

  # Cloud
  before_action :set_cloud, only: [
    :boot_cloud, :unboot_cloud, :cloud_delete, :cloud_modify, :subnet_add
  ]

  # Subnet
  before_action :set_subnet, only: [
    :boot_subnet, :unboot_subnet, :subnet_delete, :subnet_modify, :instance_add
  ]

  # Instance
  before_action :set_instance, only: [
    :boot_instance, :unboot_instance, :instance_role_add, :instance_delete, :instance_bash_history, :instance_chef_error, :instance_modify,
    :instance_dynamic_ip_roll
  ]

  # Group
  before_action :set_group, only: [
    :group_delete, :group_modify, :group_admin_access_add, :group_user_access_add, :group_player_add, 
    :group_student_group_add, :group_student_group_remove, :group_instructions_get, :group_instructions_modify
  ]
  before_action :set_instance_group, only: [
    :group_admin_access_remove, :group_user_access_remove
  ]
  before_action :set_player, only: [
    :group_player_delete
  ]

  # Role
  before_action :set_role, only: [
    :role_recipe_add, :role_delete, :role_modify, :role_package_add, :role_package_remove
  ]
  before_action :set_recipe, only: [
    :recipe_remove, :recipe_update, :recipe_update_view, :recipe_update, :recipe_view
  ]
  before_action :set_role_recipe, only: [
    :role_recipe_remove
  ]
  before_action :set_instance_role, only: [
    :instance_role_remove
  ]
  before_action :set_question, only: [
    :scoring_question_delete, :scoring_question_modify, :scoring_question_move_up, :scoring_question_move_down
  ]
  before_action :set_student, only: [
    :scoring_answers_show
  ]
  before_action :set_answer, only: [
    :scoring_answer_essay_show, :scoring_answer_comment, :scoring_answer_comment_show, 
    :scoring_answer_comment_edit_show, :scoring_answer_comment_edit, :scoring_answer_essay_grade,
    :scoring_answer_essay_grade_edit, :scoring_answer_essay_grade_delete
  ]

  # GET /scenarios
  # GET /scenarios.json
  def index
    @scenarios = []
    if @user.is_admin?
      @scenarios = Scenario.all
    else
      @scenarios = Scenario.where(user_id: current_user.id)
    end
  end

  # GET /scenarios/1
  # GET /scenarios/1.json
  def show
    # @clone = params[:clone]
    #@scenario.check_status
  end

  # GET /scenarios/new
  def new
    @scenario = Scenario.new
    @templates = []
    if Rails.env == 'production'
      @templates << {title: 'Production', headers: YmlRecord.yml_headers('production', @user)}
      @templates << {title: 'Local', headers: YmlRecord.yml_headers('local', @user)}
    elsif Rails.env == 'development'
      @templates << {title: 'Development', headers: YmlRecord.yml_headers('development', @user)}
      @templates << {title: 'Production', headers: YmlRecord.yml_headers('production', @user)}
      @templates << {title: 'Local', headers: YmlRecord.yml_headers('local', @user)}
      @templates << {title: 'Test', headers: YmlRecord.yml_headers('test', @user)}
    elsif Rails.env == 'test'
      @templates << {title: 'Test', headers: YmlRecord.yml_headers('test', @user)}
    end
    @templates << {title: 'Custom', headers: YmlRecord.yml_headers('custom', @user)}
  end

  # GET /scenarios/1/edit
  def edit
    @templates = []
  end

  # POST /scenarios
  # POST /scenarios.json
  def create
    @scenario = @user.scenarios.new(scenario_params)
    @scenario.save

    respond_to do |format|
      if @scenario.errors.any?
        @scenario.destroy
        if Rails.env == 'production'
          format.html { redirect_to '/scenarios/new', alert: "There was an error creating Scenario #{@scenario.name} please contact administrator."}
        else
          format.html { redirect_to '/scenarios/new', alert: "There was an error creating Scenario #{@scenario.name}. #{@scenario.errors.messages}"}
        end
      else
        format.html { redirect_to @scenario, notice: 'Scenario was successfully created.' }
      end
    end
  end

  # PATCH/PUT /scenarios/1
  # PATCH/PUT /scenarios/1.json
  def update
    respond_to do |format|
      if @scenario.update(scenario_params)
        format.html { redirect_to @scenario, notice: 'Scenario was successfully updated.' }
        format.json { render :show, status: :ok, location: @scenario }
      else
        format.html { render :edit }
        format.json { render json: @scenario.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_custom
    @scenario = ScenarioManagement.new.custom_create(params[:name], @user)
    respond_to do |format|
      format.js { render "scenarios/js/scenario/create_custom.js.erb", layout: false }
    end
  end

  def obliterate_custom
    @name, path_graveyard_scenario = ScenarioManagement.new.obliterate_custom(params[:filename], @user)

    respond_to do |format|
      format.js { render "scenarios/js/scenario/obliterate_custom.js.erb", layout: false }
    end
  end

  def destroyme
    if not @scenario.modifiable?
      if @scenario.destroy
        respond_to do |format|
          format.js { render js: "window.location.pathname='/scenarios'" }
        end
      else
        respond_to do |format|
          format.js { render 'scenarios/js/scenario/destroy.js.erb', :layout => false }
        end
      end
    elsif params[:save] == nil and @scenario.modified?
      respond_to do |format|
        format.js { render 'scenarios/js/scenario/destroy.js.erb', :layout => false }
      end
    else
      if params[:save] == "true"
        @scenario.update_yml
      end
      if @scenario.destroy
        respond_to do |format|
          format.js { render js: "window.location.pathname='/scenarios'" }
        end
      else 
        respond_to do |format|
          format.js { render 'scenarios/js/scenario/destroy.js.erb', :layout => false }
        end
      end
    end

  end

  def save
    @scenario.update_yml
    respond_to do |format|
      format.js { render 'scenarios/js/scenario/save.js.erb', :layout => false }
    end
  end

  def save_as
    @scenario.change_name(params[:name])
    respond_to do |format|
      format.js { render 'scenarios/js/scenario/save_as.js.erb', :layout => false }
    end
  end

  def clone
    @clone = @scenario.clone(params[:name])
    respond_to do |format|
      format.js { render "scenarios/js/scenario/clone.js.erb", layout: false }
    end
  end

  def clone_new
    @clone = ScenarioManagement.new.clone_from_name(params[:name], params[:location], params[:newname], @user)
    respond_to do |format|
      format.js { render "scenarios/js/scenario/clone_new.js.erb", layout: false }
    end
  end

  def clone_set
    clone = Scenario.find(params[:clone_id])
    redirect_to clone, notice: 'Scenario was successfully cloned.'
  end

  def status
    @student_answers_update = []
    if params[:student_answers]
      params[:student_answers].each do |key, value|
        if student = @scenario.find_student(value['student_id'].to_i)
          oldlist = value['answers'].split(',').map{ |n| n.to_i}
          newlist = @scenario.answers_list(student)
          if (oldlist.size != newlist.size) or not (oldlist - newlist).blank?
            @student_answers_update << { student: student, show: value['show'] }
          end
        end
      end
    end

    @scenario.status_update

    if @scenario.booted?
      @scenario_status = @scenario.instances_initialized? ? "booted" : "initializing"
    else
      @scenario_status = @scenario.status
    end

    respond_to do |format|
      format.js { render 'scenarios/js/status.js.erb', :layout => false }
    end
  end

  #############################################################
  # BOOTING

  def boot
    @scenario.delay(queue: 'scenario').boot(background: true)
    respond_to do |format|
      format.js { render 'scenarios/js/boot/boot_scenario.js.erb', :layout => false }
    end
  end

  def unboot
    @scenario.delay(queue: 'scenario').unboot(background: true)
    respond_to do |format|
      format.js { render 'scenarios/js/boot/unboot_scenario.js.erb', :layout => false }
    end
  end

  def boot_cloud
    @cloud.delay(queue: 'cloud').boot(background: true)
    respond_to  do |format|
      format.js { render template: 'scenarios/js/boot/boot_cloud.js.erb', layout: false }
    end
  end

  def unboot_cloud
    @cloud.delay(queue: 'cloud').unboot(background: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/unboot_cloud.js.erb',  layout: false }
    end
  end

  def boot_subnet
    @subnet.delay(queue: 'subnet').boot(background: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/boot_subnet.js.erb', layout: false }
    end
  end

  def unboot_subnet
    @subnet.delay(queue: 'subnet').unboot(background: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/unboot_subnet.js.erb', layout: false }
    end
  end

  def boot_instance
    @instance.delay(queue: 'instance').boot(background: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/boot_instance.js.erb', layout: false }
    end
  end

  def unboot_instance
    @instance.delay(queue: 'instance').unboot(background: true)
    respond_to do |format|
      format.js { render template: 'scenarios/js/boot/unboot_instance.js.erb', layout: false }
    end
  end

  def pause
    @scenario.pause
    respond_to do |format|
      format.js { render 'scenarios/js/boot/pause.js.erb', :layout => false }
    end
  end

  def start
    @scenario.start
    respond_to do |format|
      format.js { render 'scenarios/js/boot/start.js.erb', :layout => false }
    end
  end

  ###############################################################
  #  Resource Modification

  # Instructions
  def instructions_get
    respond_to do |format|
      format.js { render template: 'scenarios/js/instructions/get.js.erb', layout: false }
    end
  end

  def instructions_modify
    @scenario.update_instructions(params[:text])
    respond_to do |format|
      format.js { render template: 'scenarios/js/instructions/modify.js.erb', layout: false }
    end
  end

  def instructions_student_get
    respond_to do |format|
      format.js { render template: 'scenarios/js/instructions/student_get.js.erb', layout: false }
    end
  end

  def instructions_student_modify
    @scenario.update_instructions_student(params[:text])
    respond_to do |format|
      format.js { render template: 'scenarios/js/instructions/student_modify.js.erb', layout: false }
    end
  end

  # CLOUD
  def cloud_add
    @cloud = @scenario.clouds.new(name: params[:name], cidr_block: params[:cidr_block])
    @cloud.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/cloud/add.js.erb', layout: false }
    end
  end

  def cloud_delete
    @cloud.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/cloud/delete.js.erb', layout: false }
    end
  end

  def cloud_modify
    @cloud.update(name: params[:name], cidr_block: params[:cidr_block])

    respond_to do |format|
      format.js { render template: 'scenarios/js/cloud/modify.js.erb', layout: false }
    end
  end

  # SUBNET
  def subnet_add
    @subnet = @cloud.subnets.new(name: params[:name], cidr_block: params[:cidr_block], internet_accessible: params[:internet_accessible])
    @subnet.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/subnet/add.js.erb', layout: false }
    end
  end

  def subnet_delete
    @subnet.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/subnet/delete.js.erb', layout: false }
    end
  end

  def subnet_modify
    @subnet.update(name: params[:name], cidr_block: params[:cidr_block], internet_accessible: params[:internet_accessible])

    respond_to do |format|
      format.js { render template: 'scenarios/js/subnet/modify.js.erb', layout: false }
    end
  end

  # INSTANCE
  def instance_add
    @instance = @subnet.instances.new(
      name: params[:name],
      ip_address: params[:ip],
      os: params[:os],
      internet_accessible: params[:internet_accessible],
      uuid: `uuidgen`.chomp
    )
    @instance.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/add.js.erb', layout: false }
    end
  end

  def instance_delete
    @instance.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/delete.js.erb', layout: false }
    end
  end

  def instance_modify
    @accessible_to_not_accessible = ((@instance.internet_accessible == true) and (params[:internet_accessible] == "false"))
    @not_accessible_to_accessible = ((@instance.internet_accessible == false) and (params[:internet_accessible] == "true"))

    @instance.update(
      name:  params[:name],
      ip_address:  params[:ip_address],
      ip_address_dynamic:  params[:ip_address_dynamic],
      internet_accessible:  params[:internet_accessible],
      os:  params[:os]
    )
    
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/modify.js.erb', layout: false }
    end
  end

  def instance_role_add
    @instance_role = @instance.role_add(params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/role_add.js.erb', layout: false }
    end
  end

  def instance_role_remove
    @instance_role.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/role_remove.js.erb', layout: false }
    end
  end

  def instance_bash_history
    @bash_history = @instance.get_bash_history.gsub("\n", "<br>").gsub('"', "'").html_safe;
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/bash_history.js.erb', layout: false }
    end
  end

  def instance_chef_error
    @chef_error = @instance.get_chef_error.gsub("\"", "\\\"").gsub(/\n/, "\\n").gsub(/\r/, "").html_safe
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/chef_error.js.erb', layout: false }
    end
  end

  def instance_dynamic_ip_roll
    @instance.ip_roll
    respond_to do |format|
      format.js { render template: 'scenarios/js/instance/dynamic_ip_roll.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Players

  def group_add
    @group = @scenario.groups.new(name: params[:name])
    @group.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/add.js.erb', layout: false }
    end
  end

  def group_delete
    @group.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/delete.js.erb', layout: false }
    end
  end

  def group_modify
    @group.update(name: params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/modify.js.erb', layout: false }
    end
  end

  def group_instructions_get
    @instructions = @group.instructions.gsub("\n", "<br>").gsub(" ", "&nbsp").gsub("'", "\"").gsub(/\r/, "").html_safe;
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/instructions_get.js.erb', layout: false }
    end
  end

  def group_instructions_modify
    @group.update_instructions(params[:text])
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/instructions_modify.js.erb', layout: false }
    end
  end

  def group_admin_access_add
    @instance = @group.scenario.instances.select { |i| i.name == params[:name] }.first
    if @instance
      @instance_group = @group.admin_access_add(@instance)
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/admin_access_add.js.erb', layout: false }
    end
  end

  def group_admin_access_remove
    @instance_group.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/admin_access_remove.js.erb', layout: false }
    end
  end

  def group_user_access_add
    @instance = @group.scenario.instances.select { |i| i.name == params[:name] }.first
    if @instance
      @instance_group = @group.user_access_add(@instance)
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/user_access_add.js.erb', layout: false }
    end
  end

  def group_user_access_remove
    @instance_group.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/user_access_remove.js.erb', layout: false }
    end
  end

  def group_player_add
    @player = @group.players.new(login: params[:login], password: params[:password])
    @player.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/group/player_add.js.erb', layout: false }
    end
  end

  def group_player_delete
    @player.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/player_delete.js.erb', layout: false }
    end
  end

  def group_student_group_add
    @student_group_name = params[:name]
    @players = @group.student_group_add(params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/student_group_add.js.erb', layout: false }
    end
  end

  def group_student_group_remove
    @student_group_name = params[:name]
    @players = @group.student_group_remove(params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/group/student_group_remove.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Roles

  def role_add
    @role = @scenario.roles.new(name: params[:name])
    @role.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/add.js.erb', layout: false }
    end
  end

  def role_delete
    @instance_role_ids = @role.instance_roles.map { |ir| ir.id }
    @role.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/delete.js.erb', layout: false }
    end
  end

  def role_modify
    @role.update(name: params[:name])
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/modify.js.erb', layout: false }
    end
  end

  def role_package_add
    @package = params[:name]
    @role.package_add(@package)
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/package_add.js.erb', layout: false }
    end
  end

  def role_package_remove
    @package = params[:name]
    @role.package_remove(@package)
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/package_remove.js.erb', layout: false }
    end
  end

  def role_recipe_add
    @recipe = @scenario.recipes.find_by_name(params[:name])
    if @recipe
      @role_recipe = @role.role_recipes.new(recipe_id: @recipe.id)
      @role_recipe.save
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/recipe_add.js.erb', layout: false }
    end
  end

  def role_recipe_remove
    @role_recipe.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/role/recipe_remove.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Recipes

  def recipe_custom_add
    # @scenario.recipe_custom_add(params[:recipe], params[:text])

    @recipe = @scenario.recipes.new(name: params[:name], custom: true)
    if @recipe and not @recipe.errors.any?
      @recipe.text_update(params[:text])
      @recipe.save
    end

    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/custom_add.js.erb', layout: false }
    end
  end

  def recipe_global_add
    @recipe = @scenario.recipes.new(name: params[:name], custom: false)
    @recipe.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/global_add.js.erb', layout: false }
    end
  end

  def recipe_global_get
    @recipes = @scenario.get_global_recipes_and_descriptions
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/global_get.js.erb', layout: false }
    end
  end

  def recipe_remove
    @role_recipes_ids = @recipe.role_recipes.map { |rr| rr.id }
    @recipe.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/remove.js.erb', layout: false }
    end
  end

  def recipe_update
    @recipe.text_update(params[:text])
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/update.js.erb', layout: false }
    end
  end

  def recipe_update_view
    if not @recipe.custom
      @error = "This is a global recipe can not update from here."
    else
      @recipe_text = @recipe.text.gsub("\"", "\\\"").gsub(/\n/, "\\n").gsub(/\r/, "").html_safe;
    end
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/update_view.js.erb', layout: false }
    end
  end

  def recipe_view
    @recipe_text = @recipe.text.gsub("\n", "<br>").gsub(" ", "&nbsp").gsub("'", "\"").gsub(/\r/, "").html_safe;
    respond_to do |format|
      format.js { render template: 'scenarios/js/recipe/view.js.erb', layout: false }
    end
  end

  ###############################################################
  #  Scoring

  # Questions
  def scoring_question_add
    values = nil
    if params[:values]
      values = []
      params[:values].each_with_index do |val, i| values << { value: val, special: params[:special][i], points: params[:value_points][i] } end
    end

    @question = @scenario.questions.new(
      type_of: params[:type],
      options: params["#{params[:type].downcase}_options"] ? params["#{params[:type].downcase}_options"] : [],
      text: params[:text],
      values: params[:type] == "Essay" ? [] : values,
      # because rails typecasts strings to integer '0' put in '-1' instead if not an integer to get proper validation
      points: params[:points].is_integer? ? params[:points] : '-1'
    )
    @question.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/question/add.js.erb', layout: false }
    end
  end

  def scoring_question_delete
    @question.destroy
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/question/delete.js.erb', layout: false }
    end
  end

  def scoring_question_modify
    values = nil
    if params[:values]
      values = []
      params[:values].each_with_index do |val, i| values << { value: val, special: params[:special][i], points: params[:value_points][i] } end
    end

    @question.update(
      type_of: params[:type],
      options: params["#{params[:type].downcase}_options"] ? params["#{params[:type].downcase}_options"] : [],
      text: params[:text],
      values: params[:type] == "Essay" ? [] : values,
      points: params[:points].is_integer? ? params[:points] : '-1'
    )
    @question.save

    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/question/modify.js.erb', layout: false }
    end
  end

  def scoring_question_move_up
    @question2 = @question.move_up
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/question/move_up.js.erb', layout: false }
    end
  end
    
  def scoring_question_move_down
    @question2 = @question.move_down
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/question/move_down.js.erb', layout: false }
    end
  end

  # Answers
  def scoring_answers_show
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/show.js.erb', layout: false }
    end
  end

  def scoring_answer_essay_show
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/essay_show.js.erb', layout: false }
    end
  end

  def scoring_answer_essay_grade
    @answer.essay_points_earned = params[:points]
    @answer.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/essay_grade.js.erb', layout: false }
    end
  end

  def scoring_answer_essay_grade_edit
    @answer.essay_points_earned = params[:points]
    @answer.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/essay_grade_edit.js.erb', layout: false }
    end
  end

  def scoring_answer_essay_grade_delete
    @answer.essay_points_earned = nil
    @answer.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/essay_grade_delete.js.erb', layout: false }
    end
  end

  def scoring_answer_comment
    @answer.comment = params[:comment]
    @answer.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/comment.js.erb', layout: false }
    end
  end

  def scoring_answer_comment_show
    @question_index = params[:question_index].to_i + 1
    @answer_index = params[:answer_index].to_i + 1
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/comment_show.js.erb', layout: false }
    end
  end

  def scoring_answer_comment_edit
    @answer.comment = params[:comment]
    @answer.save
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/comment_edit.js.erb', layout: false }
    end
  end

  def scoring_answer_comment_edit_show
    @question_index = params[:question_index].to_i + 1
    @answer_index = params[:answer_index].to_i + 1
    respond_to do |format|
      format.js { render template: 'scenarios/js/scoring/answer/comment_edit_show.js.erb', layout: false }
    end
  end



  ###############################################################
  #  Helpers

  def log_get
    @htmllog = @scenario.statistic.boot_log_last_read.gsub("\n", "<br>").html_safe;
    respond_to do |format|
      format.js { render template: 'scenarios/js/log.js.erb', layout: false }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(current_user.id)
    end

    def set_scenario
      if not @scenario = Scenario.find_by_id(params[:id])
        redirect_to '/scenarios/'
      end
      if not @user.owns? @scenario
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_cloud
      @cloud = Cloud.find(params[:cloud_id])
      if not @user.owns? @cloud
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_subnet
      @subnet = Subnet.find(params[:subnet_id])
      if not @user.owns? @subnet
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance
      @instance = Instance.find(params[:instance_id])
      if not @user.owns? @instance
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_group
      @group = Group.find(params[:group_id])
      if not @user.owns? @group
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance_role
      @instance_role = InstanceRole.find(params[:instance_role_id])
      if not @user.owns? @instance_role
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_role
      @role = Role.find(params[:role_id])
      if not @user.owns? @role
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_role_recipe
      @role_recipe = RoleRecipe.find(params[:role_recipe_id])
      if not @user.owns? @role_recipe
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_recipe
      @recipe = Recipe.find(params[:recipe_id])
      if not @user.owns? @recipe
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_player
      @player = Player.find(params[:player_id])
      if not @user.owns? @player
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance_group
      @instance_group = InstanceGroup.find(params[:instance_group_id])
      if not @user.owns? @instance_group
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_question
      @question = Question.find(params[:question_id])
      if not @user.owns? @question
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_student
      @student = User.find(params[:student_id])
      if not @scenario.has_student? @student
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_answer
      @answer = Answer.find(params[:answer_id])
      if not @scenario.has_question? @answer.question
        head :ok, content_type: "text/html"
        return
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def scenario_params
      params.require(:scenario).permit(:game_type, :name, :template, :location)
    end
end
