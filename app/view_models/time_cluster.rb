# frozen_string_literal: true

class TimeCluster
  attr_reader :split_times_data

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:finish, :split_times_data],
                           exclusive: [:finish, :split_times_data],
                           class: self.class)
    @finish = args[:finish]
    @split_times_data = args[:split_times_data]
  end

  def finish?
    @finish
  end

  def aid_time_recordable?
    split_times_data.many?
  end

  def segment_time
    @segment_time ||= compacted_segment_times.first
  end

  def time_in_aid
    @time_in_aid ||= compacted_segment_times.last if compacted_segment_times.many?
  end

  def times_from_start
    @times_from_start ||= split_times_data.map(&:time_from_start)
  end

  def days_and_times
    @days_and_times ||= split_times_data.map(&:day_and_time)
  end

  def day_and_time_strings
    @days_and_times ||= split_times_data.map(&:day_and_time_string)
  end

  def time_data_statuses
    @time_data_statuses ||= split_times_data.map(&:data_status)
  end

  def pacer_flags
    @pacer_flags ||= split_times_data.map(&:pacer)
  end

  def stopped_here_flags
    @stopped_here_flags ||= split_times_data.map(&:stopped_here?)
  end

  def split_time_ids
    @split_time_ids ||= split_times_data.map(&:id)
  end

  def stopped_here?
    @stopped_here ||= stopped_here_flags.any?
  end

  private

  def compacted_segment_times
    @compacted_segment_times ||= split_times_data.map(&:segment_time).compact
  end
end
