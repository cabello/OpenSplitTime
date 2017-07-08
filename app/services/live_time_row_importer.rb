class LiveTimeRowImporter

  def self.import(args)
    importer = new(args)
    importer.import
    importer.returned_rows
  end

  def initialize(args)
    ArgsValidator.validate(params: args,
                           required: [:event, :time_rows],
                           exclusive: [:event, :time_rows],
                           class: self.class)
    @event = args[:event]
    @time_rows = args[:time_rows].map(&:last) # time_row.first is a unneeded id; time_row.last contains all needed data
    @times_container ||= SegmentTimesContainer.new(calc_model: :stats)
    @unsaved_rows = []
    @saved_split_times = {}
  end

  def import
    time_rows.each do |time_row|
      effort_data = LiveEffortData.new(event: event,
                                       params: time_row,
                                       ordered_splits: ordered_splits,
                                       times_container: times_container)

      # If just one row was submitted, assume the user has noticed if data status is bad or questionable,
      # or if times will be overwritten, so call bulk_create_or_update with force option. If more than one
      # row was submitted, call bulk_create_or_update without force option.

      if effort_data.valid? && (effort_data.clean? || force_option?)
        if create_or_update_times(effort_data)
          EffortOffsetTimeAdjuster.adjust(effort: effort_data.effort)
        end
      else
        unsaved_rows << effort_data.response_row
      end
    end
    match_live_times
    notify_followers if event.available_live
  end

  def returned_rows
    {returned_rows: unsaved_rows}.camelize_keys
  end

  private

  EXTRACTABLE_ATTRIBUTES = %w(time_from_start data_status pacer remarks stopped_here live_time_id)

  attr_reader :event, :time_rows, :times_container
  attr_accessor :unsaved_rows, :saved_split_times

  # Returns true if all available times (in or out or both) are created/updated.
  # Returns false if any create/update is attempted but rejected

  def create_or_update_times(effort_data)
    effort = effort_data.effort
    indexed_split_times = effort_data.indexed_existing_split_times
    row_success = true
    participant_id = effort_data.participant_id || 0 # Id 0 is the dump for efforts with no participant_id
    saved_split_times[participant_id] ||= []

    effort_data.proposed_split_times.each do |proposed_split_time|
      working_split_time = indexed_split_times[proposed_split_time.time_point] || proposed_split_time
      saved_split_time = create_or_update_split_time(proposed_split_time, working_split_time)
      if saved_split_time
        effort.stop(saved_split_time) if saved_split_time.stopped_here
        EffortDataStatusSetter.set_data_status(effort: effort_data.effort, times_container: times_container)
        saved_split_times[participant_id] << saved_split_time
      else
        unsaved_rows << effort_data.response_row
        row_success = false
      end
    end
    row_success
  end

  def create_or_update_split_time(proposed_split_time, working_split_time)
    working_split_time if working_split_time.update(extracted_attributes(proposed_split_time))
  end

  # Extract only those extractable attributes that are non-nil (false must be extracted)
  def extracted_attributes(split_time)
    EXTRACTABLE_ATTRIBUTES.map { |attribute| [attribute, split_time.send(attribute)] }.to_h
        .select { |_, value| !value.nil? }
  end

  def ordered_splits
    @ordered_splits ||= event.ordered_splits.to_a
  end

  def force_option?
    time_rows.size == 1
  end

  def match_live_times
    split_times = saved_split_times.values.flatten.select { |st| st.live_time_id.present? }
    split_times.each do |split_time|
      live_time = LiveTime.find(split_time.live_time_id)
      live_time.update(split_time: split_time)
    end
  end

  def notify_followers
    saved_split_times.each do |participant_id, split_times|
      NotifyFollowersJob.perform_later(participant_id: participant_id,
                                       split_time_ids: split_times.map(&:id),
                                       multi_lap: event.multiple_laps?) unless participant_id.zero?
    end
  end
end
