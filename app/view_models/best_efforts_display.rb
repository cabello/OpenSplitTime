class BestEffortsDisplay

  delegate :name, :simple?, :to_param, to: :course
  delegate :distance, :vert_gain, :vert_loss, :begin_lap, :end_lap,
           :begin_id, :end_id, :begin_bitkey, :end_bitkey, to: :segment

  def initialize(course, params = {})
    @course = course
    @params = params
    @events = Event.where(id: all_efforts.map(&:event_id).uniq, concealed: false).order(start_time: :desc).to_a
  end

  def filtered_efforts
    selected_efforts.paginate(page: params[:page], per_page: 25)
  end

  def selected_efforts
    (gender_text != 'combined') || params[:search].present? ?
        all_efforts.select { |effort| filter_ids.include?(effort.id) } :
        all_efforts
  end

  def all_efforts_count
    all_efforts.size
  end

  def filtered_efforts_count
    filtered_efforts.total_entries
  end

  def effort_rows
    @effort_rows ||= filtered_efforts.map { |effort| EffortRow.new(effort) }
  end

  def segment_name
    segment_is_full_course? ? 'Full Course' : segment.name
  end

  def events_count
    events.size
  end

  def earliest_event_date
    events.last.start_time.to_date.to_formatted_s(:long)
  end

  def latest_event_date
    events.first.start_time.to_date.to_formatted_s(:long)
  end

  def most_recent_event_date
    most_recent_event && most_recent_event.start_time.to_date.to_formatted_s(:long)
  end

  def most_recent_event
    events.select { |event| event.start_time < Time.now }.sort_by(&:start_time).last
  end

  def title_text
    "#{gender_text.upcase} • #{segment_name.upcase}"
  end

  def time_header_text
    segment_is_full_course? ? 'Course Time' : 'Segment Time'
  end

  def gender_text
    case params[:gender]
    when [0]
      'male'
    when [1]
      'female'
    else
      'combined'
    end
  end

  private

  attr_reader :course, :events, :params

  def ordered_splits
    @ordered_splits ||= course.ordered_splits
  end

  def segment
    return @segment if defined?(@segment)
    split1 = ordered_splits.find { |split| [split.id, split.slug].compact.include?(params[:split1]) } || ordered_splits.first
    split2 = ordered_splits.find { |split| [split.id, split.slug].compact.include?(params[:split1]) } || ordered_splits.last
    begin_split, end_split = [split1, split2].sort_by { |split| ordered_splits.index(split) }
    @segment = Segment.new(begin_point: TimePoint.new(1, begin_split.id, begin_split.bitkeys.last),
                           end_point: TimePoint.new(1, end_split.id, end_split.bitkeys.first),
                           begin_lap_split: LapSplit.new(1, begin_split),
                           end_lap_split: LapSplit.new(1, end_split))
  end

  def segment_is_full_course?
    segment.full_course?
  end

  def filter_ids
    @filter_ids ||= Effort.where(gender: params[:gender]).search(params[:search]).ids.to_set
  end

  def all_efforts
    @all_efforts ||= Effort.find_by_sql(EffortQuery.over_segment(segment))
  end
end