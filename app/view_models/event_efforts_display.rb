class EventEffortsDisplay

  attr_accessor :filtered_efforts
  attr_reader :event, :effort_rows
  delegate :name, :start_time, :course, :race, :simple?, to: :event

  # initialize(event, params = {})
  # event is an ordinary event object
  # params is passed from the controller and may include
  # params[:search_param] (from user search input)
  # and params[:page] (for will_paginate)

  def initialize(event, params = {})
    @event = event
    @event_final_split_id = event.finish_split.id if event.finish_split
    get_efforts(params)
    @effort_rows = []
    create_effort_rows
  end

  def all_efforts_count
    all_efforts.count
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

  private

  attr_accessor :all_efforts, :event_final_split_id

  def get_efforts(params)
    self.all_efforts = event.efforts.sorted_with_finish_status
    self.filtered_efforts = event.efforts
                                .search(params[:search_param])
                                .sorted_with_finish_status
                                .paginate(page: params[:page], per_page: 25)
  end

  def create_effort_rows
    filtered_efforts.each do |effort|
      effort_row = EffortRow.new(effort, overall_place: overall_place(effort),
                                 gender_place: gender_place(effort),
                                 finish_status: finish_status(effort))
      effort_rows << effort_row
    end
  end

  def finish_status(effort)
    return effort.time_from_start if effort.final_split_id == event_final_split_id
    return "Dropped at #{effort.final_split_name}" if effort.final_split_id
    "In progress"
  end

  def overall_place(effort)
    sorted_effort_ids.index(effort.id) + 1
  end

  def gender_place(effort)
    sorted_genders[0...overall_place(effort)].count(effort.gender)
  end

  def sorted_effort_ids
    all_efforts.map(&:id)
  end

  def sorted_genders
    all_efforts.map(&:gender)
  end

end