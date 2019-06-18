class SchedulesController < ApplicationController
  before_action :set_schedule, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_admin_or_instructor!

  # GET /schedules
  # GET /schedules.json
  def index
    @schedules = Schedule.all
  end

  # GET /schedules/1
  # GET /schedules/1.json
  def show
  end

  # GET /schedules/new
  def new
    @schedule = Schedule.new
    @templates = []
    @scenario_list = []
    if Rails.env == 'production'
      @templates << YmlRecord.yml_headers('production', current_user)
      @templates << YmlRecord.yml_headers('local', current_user)
    elsif Rails.env == 'development'
      @templates << YmlRecord.yml_headers('development', current_user)
      @templates << YmlRecord.yml_headers('production', current_user)
      @templates << YmlRecord.yml_headers('local', current_user)
      @templates << YmlRecord.yml_headers('test', current_user)
    elsif Rails.env == 'test'
      @templates << YmlRecord.yml_headers('test', current_user)
    end
    @templates << YmlRecord.yml_headers('custom', current_user)
    @templates.each {|x| x.each {|y| @scenario_list.push(y[:name])}}
  end

  # GET /schedules/1/edit
  def edit
  end

  # POST /schedules
  # POST /schedules.json
  def create
    @schedule = current_user.schedules.new(schedule_params)
    @schedule.save
    
    if @schedule.errors.any?
      render template: 'schedules/js/create.js.erb'
    end
  end

  # PATCH/PUT /schedules/1
  # PATCH/PUT /schedules/1.json
  def update
    respond_to do |format|
      if @schedule.update(schedule_params)
        format.html { redirect_to @schedule, notice: 'Schedule was successfully updated.' }
        format.json { render :show, status: :ok, location: @schedule }
      else
        format.html { render :edit }
        format.json { render json: @schedule.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /schedules/1
  # DELETE /schedules/1.json
  def destroy
    @schedule.destroy
    respond_to do |format|
      format.html { redirect_to schedules_url, notice: 'Schedule was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_schedule
      @schedule = Schedule.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def schedule_params
      params.require(:schedule).permit(:user_id, :scenario, :scenario_location, :start_time, :end_time)
    end

end
