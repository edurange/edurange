class StudentScenariosController < ApplicationController
  before_action :authenticate_student!

  before_action :set_scenario, only: [:show, :answer_string, :answer_number, :answer_essay]
  before_action :set_question, only: [:answer_string, :answer_number, :answer_essay]
  before_action :set_answer, only: [:answer_essay_delete, :answer_essay_show, :answer_comment_show]

  def show
    @player = @scenario.players.find_by(user: current_user)
  end

  def answer_string
    @answer = @question.answer_string(params[:text], current_user.id)
    respond_to do |format|
      format.js { render "student_scenarios/js/answer_string.js.erb", layout: false }
    end
  end

  def answer_number
    @answer = @question.answer_number(params[:text], current_user.id)
    respond_to do |format|
      format.js { render "student_scenarios/js/answer_number.js.erb", layout: false }
    end
  end

  def answer_essay
    @answer = @question.answer_essay(params[:text], current_user.id)
    respond_to do |format|
      format.js { render "student_scenarios/js/answer_essay.js.erb", layout: false }
    end
  end

  def answer_essay_delete
    @answer.destroy
    respond_to do |format|
      format.js { render "student_scenarios/js/answer_essay_delete.js.erb", layout: false }
    end
  end

  def answer_essay_show
    respond_to do |format|
      format.js { render "student_scenarios/js/answer_essay_show.js.erb", layout: false }
    end
  end

  def answer_comment_show
    @question_index = params[:question_index].to_i + 1
    @answer_index = params[:answer_index].to_i + 1
    respond_to do |format|
      format.js { render "student_scenarios/js/answer_comment_show.js.erb", layout: false }
    end
  end

  def show_scenario_guide
    @scenario = Scenario.find(params.require(:scenario_id))
    render 'scenarios/guide'
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_scenario
      if @scenario = Scenario.find_by_id(params.require(:scenario_id))
        if not @scenario.has_student? current_user
          redirect_to '/student'
        end
      else
        redirect_to '/student'
      end
    end

    def set_question
      @question = Question.find(params[:question_id])
      if not @scenario.questions.find_by_id(@question.id)
        head :ok, content_type: "text/html"
        return
      end
    end

    def set_answer
      @answer = Answer.find(params[:answer_id])
      if not current_user.owns? @answer
        head :ok, content_type: "text/html"
        return
      end
    end

end
