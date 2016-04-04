class EffortsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_effort, except: [:index, :new, :create]
  after_action :verify_authorized, except: [:index, :show]

  def index

  end

  def show
    session[:return_to] = effort_path(@effort)
  end

  def new
    @effort = Effort.new
    @event = Event.find(params[:event_id]) if params[:event_id]
    authorize @effort
  end

  def edit
    @event = Event.find(@effort.event_id)
    authorize @effort
  end

  def create
    @effort = Effort.new(effort_params)
    authorize @effort

    if @effort.save
      redirect_to session.delete(:return_to) || @effort
    else
      render 'new'
    end
  end

  def update
    authorize @effort

    if @effort.update(effort_params)
      redirect_to session.delete(:return_to) || @effort
    else
      render 'edit'
    end
  end

  def destroy
    authorize @effort
    @effort.destroy

    session[:return_to] = params[:referrer_path] if params[:referrer_path]
    redirect_to session.delete(:return_to) || root_path
  end

  def associate_participant
    @event = Event.find(params[:event_id])
    authorize @event
    @effort.participant_id = params[:participant_id]

    if @effort.save
      @participant = Participant.find(params[:participant_id])
      @participant.pull_data_from_effort(@effort.id)
      redirect_to reconcile_event_path(params[:event_id])
    else
      redirect_to reconcile_event_path(params[:event_id]),
                  error: 'Effort was not associated with participant'
    end
  end

  def associate_participants
    @event = Event.find(params[:event_id])
    authorize @event
    if params[:ids].nil?
      redirect_to reconcile_event_path(@event)
    else
      effort_ids = params[:ids].keys
      participant_ids = params[:ids].values
      (0..effort_ids.size - 1).each do |i|
        @effort = Effort.find(effort_ids[i])
        authorize @effort
        @participant = Participant.find(participant_ids[i])
        @participant.pull_data_from_effort(@effort.id)
      end
      redirect_to reconcile_event_path(@event)
    end
  end

  def fix_finish_time
    authorize @effort
    @event = Event.find(params[:event_id])
    @split_time = @effort.finish_split_time
    wrong_time = @split_time.time_from_start
    @split_time.update_attributes(time_from_start: wrong_time + 24.hours)
    @event.touch # Force cache update
    redirect_to event_path(@event)
  end

  private

  def effort_params
    params.require(:effort).permit(:first_name, :last_name, :gender, :wave, :bib_number, :age,
                                   :city, :state_code, :country_code, :start_time, :finished)
  end

  def query_params
    params.permit(:name)
  end

  def set_effort
    @effort = Effort.find(params[:id])
  end

end