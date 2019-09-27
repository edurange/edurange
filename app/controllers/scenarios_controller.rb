class ScenariosController < ApplicationController
  layout 'application', only: [:index, :new]
  before_action :authenticate_admin_or_instructor!

  before_action :set_scenario, only: [
    :edit, :update, :show, :destroy,
    :start, :stop, :archive, :unarchive, :restart,
    :players, :player_modify, :player_student_group_add, :player_add, :player_group_add, :player_delete, :player_group_admin_access_add, :player_group_user_access_add,
    :scoring, :scoring_question_add, :scoring_answers_show, :scoring_answer_essay_show, :scoring_answer_comment, :scoring_answer_comment_show,
    :scoring_answer_comment_edit, :scoring_answer_comment_edit_show, :scoring_answer_essay_grade, :scoring_answer_essay_grade_edit,
    :scoring_answer_essay_grade_delete,
    :guide,
    :instances
  ]

  before_action :set_group, only: [
    :group_delete, :group_modify, :group_admin_access_add, :group_user_access_add, :group_player_add,
    :group_student_group_add, :group_student_group_remove, :group_instructions_get, :group_instructions_modify
  ]
  before_action :set_player, only: [
    :group_player_delete
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

  def index
    @scenarios = Scenario.all.order(updated_at: :desc)

    @selected_statuses = params[:status] || Scenario.statuses.keys - ['archived']

    @scenarios = if !@selected_statuses.blank?
      @scenarios.where(status: @selected_statuses)
    else
      @scenarios.not_archived
    end

    if not current_user.is_admin?
      @scenarios = @scenarios.where(user: current_user)
    end
  end

  def show
    # @clone = params[:clone]
    #@scenario.check_status
  end

  def new
    @templates = Scenario.templates.select{|s| s.location == 'production'}
  end

  def edit
    @templates = []
  end

  def create
    # Curious where ScenarioLoader lives? lib/scenario_loader.rb
    @scenario = ScenarioLoader.new(user: current_user,
                                   name: new_scenario_params[:name],
                                   location: new_scenario_params[:location])
                              .fire!

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

  def previous_action
    previous = Rails.application.routes.recognize_path(request.referrer)
    "#{previous[:controller]}\##{previous[:action]}"
  end

  def update
    respond_to do |format|
      if @scenario.update(scenario_params)
        format.html do
          message = 'Scenario was successfully updated.'
          if previous_action == 'scenarios#edit' then
            redirect_to(@scenario, notice: message)
          else
            redirect_back(fallback_location: @scenario, notice: message)
          end
        end
        format.json { render :show, status: :ok, location: @scenario }
      else
        format.html { render :edit }
        format.json { render json: @scenario.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @scenario.destroy
      redirect_back(fallback_location: scenarios_path, notice: "Scenario destroyed.")
    else
      redirect_back(fallback_location: scenarios_path, error: "Could not destroy scenario.")
    end
  end

  def start
    StartScenarioJob.perform_later(@scenario)
    redirect_back(
      fallback_location: scenario_path(@scenario),
      notice: "Starting scenario."
    )
  end

  def stop
    StopScenarioJob.perform_later(@scenario)
    redirect_back(
      fallback_location: scenario_path(@scenario),
      notice: "Stopping scenario."
    )
  end

  def restart
    RestartScenarioJob.perform_later(@scenario)
    redirect_back(
      fallback_location: scenario_path(@scenario),
      notice: "Restarting scenario."
    )
  end

  def archive
    @scenario.archive!
    redirect_back(
      fallback_location: scenario_path(@scenario),
      notice: "Archived scenario."
    )
  end

  def unarchive
    @scenario.unarchive!
    redirect_back(
      fallback_location: scenario_path(@scenario),
      notice: "Unarchived scenario."
    )
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

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_scenario
      if not @scenario = Scenario.find_by_id(params[:id])
        redirect_to '/scenarios/'
      end
      if not current_user.owns? @scenario
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_cloud
      @cloud = Cloud.find(params[:cloud_id])
      if not current_user.owns? @cloud
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_subnet
      @subnet = Subnet.find(params[:subnet_id])
      if not current_user.owns? @subnet
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance
      @instance = Instance.find(params[:instance_id])
      if not current_user.owns? @instance
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_group
      @group = Group.find(params[:group_id])
      if not current_user.owns? @group
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance_role
      @instance_role = InstanceRole.find(params[:instance_role_id])
      if not current_user.owns? @instance_role
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_role
      @role = Role.find(params[:role_id])
      if not current_user.owns? @role
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_role_recipe
      @role_recipe = RoleRecipe.find(params[:role_recipe_id])
      if not current_user.owns? @role_recipe
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_recipe
      @recipe = Recipe.find(params[:recipe_id])
      if not current_user.owns? @recipe
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_player
      @player = Player.find(params[:player_id])
      if not current_user.owns? @player
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_instance_group
      @instance_group = InstanceGroup.find(params[:instance_group_id])
      if not current_user.owns? @instance_group
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_question
      @question = Question.find(params[:question_id])
      if not current_user.owns? @question
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
    def new_scenario_params
      params.require(:scenario).permit(:name, :location)
    end
end
