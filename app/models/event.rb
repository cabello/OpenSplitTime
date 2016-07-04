class Event < ActiveRecord::Base
  include Auditable
  include SplitMethods
  strip_attributes collapse_spaces: true
  belongs_to :course, touch: true
  belongs_to :race
  has_many :efforts, dependent: :destroy
  has_many :aid_stations, dependent: :destroy
  has_many :splits, through: :aid_stations

  validates_presence_of :course_id, :name, :start_time
  validates_uniqueness_of :name, case_sensitive: false

  scope :recent, -> (max) { where('start_time < ?', Time.now).order(start_time: :desc).limit(max) }
  scope :most_recent, -> { where('start_time < ?', Time.now).order(start_time: :desc).first }
  scope :latest, -> { order(start_time: :desc).first }
  scope :earliest, -> { order(:start_time).first }
  scope :name_search, -> (search_param) { where('name ILIKE ?', "%#{search_param}%") }
  scope :select_with_params, -> (params) { search(params[:search_param])
                                               .where(demo: false)
                                               .select("events.*, COUNT(efforts.id) as effort_count")
                                               .joins("LEFT OUTER JOIN efforts ON (efforts.event_id = events.id)")
                                               .group("events.id")
                                               .order(start_time: :desc) }

  def all_splits_on_course?
    splits.joins(:course).group(:course_id).count.size == 1
  end

  def self.search(param)
    return all if param.blank?
    name_search(param)
  end

  def reconciled_efforts
    efforts.where.not(participant_id: nil)
  end

  def unreconciled_efforts
    efforts.where(participant_id: nil)
  end

  def unreconciled_efforts?
    unreconciled_efforts.count > 0
  end

  def set_all_course_splits
    splits << course.splits
  end

  def time_hashes_similar_events
    result_hash = {}
    split_ids = ordered_split_ids
    effort_ids = Effort.includes(:event).where(dropped_split_id: nil, events: {course_id: course_id}).order('events.start_time DESC').limit(200).pluck(:id)
    complete_hash = SplitTime.valid_status
                        .select(:split_id, :sub_split_bitkey, :effort_id, :time_from_start)
                        .where(split_id: split_ids, effort_id: effort_ids)
                        .group_by(&:bitkey_hash)
    complete_hash.keys.each do |bitkey_hash|
      result_hash[bitkey_hash] = Hash[complete_hash[bitkey_hash].map { |split_time| [split_time.effort_id, split_time.time_from_start] }]
    end
    result_hash
  end

  def split_times
    SplitTime.includes(:effort).where(efforts: {event_id: id})
  end

  def split_time_hash
    split_times.group_by(&:bitkey_hash)
  end

  def efforts_sorted
    efforts.sorted_with_finish_status
  end

  def ids_sorted
    efforts.sorted_with_finish_status.map(&:id)
  end

  def combined_places(effort)
    raw_sort = efforts_sorted
    overall_place = raw_sort.map(&:id).index(effort.id) + 1
    gender_place = raw_sort[0...overall_place].map(&:gender).count(effort.gender)
    return overall_place, gender_place
  end

  def overall_place(effort)
    ids_sorted.index(effort.id) + 1
  end

  def gender_place(effort)
    combined_places(effort)[1]
  end

  def sub_split_bitkey_hashes
    ordered_splits.map(&:sub_split_bitkey_hashes).flatten
  end

  def course_name
    course.name
  end

  def race_name
    race ? race.name : nil
  end

end