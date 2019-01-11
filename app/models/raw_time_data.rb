# frozen_string_literal: true

# This Struct is a lightweight alternative to RawTime when many objects are needed.

RawTimeData = Struct.new(:id, :event_group_id, :bib_number, :split_name, :bitkey, :stopped_here, :data_status_numeric,
                         :absolute_time_string, :day_and_time_string, :military_time, :source, :created_by, :pulled_by, keyword_init: true) do

  def absolute_time
    absolute_time_string&.to_datetime
  end

  def day_and_time
    day_and_time_string&.to_datetime
  end

  def data_status
    RawTime.data_statuses.invert[data_status_numeric]
  end

  # This code should be extracted and combined with the identical code in TimeRecordable

  def source_text
    case
    when source.start_with?('ost-remote')
      "OSTR (#{source.last(4)})"
    when source.start_with?('ost-live-entry')
      "Live Entry (#{created_by})"
    else
      source
    end
  end

  def stopped_here?
    stopped_here
  end
end