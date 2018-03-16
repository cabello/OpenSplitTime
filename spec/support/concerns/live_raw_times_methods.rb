RSpec.shared_examples_for 'live_raw_times_methods' do
  let(:model) { described_class }
  let(:model_name) { model.name.underscore.to_sym }
  let(:in_bitkey) { SubSplit::IN_BITKEY }
  let(:out_bitkey) { SubSplit::OUT_BITKEY }

  describe '#military_time' do
    context 'when absolute_time exists and a zone string argument is passed' do
      it 'returns the time component in hh:mm:ss format in the specified time zone' do
        resource = build_stubbed(model_name, absolute_time: '2017-07-31 09:30:45 -0000', entered_time: '0123')
        zone = 'Eastern Time (US & Canada)'
        expect(resource.military_time(zone)).to eq('05:30:45')
      end
    end

    context 'when absolute_time exists and a TimeZone object argument is passed' do
      it 'returns the time component in hh:mm:ss format in the specified time zone' do
        resource = build_stubbed(model_name, absolute_time: '2017-07-31 09:30:45 -0000', entered_time: '0123')
        zone = ActiveSupport::TimeZone['Eastern Time (US & Canada)']
        expect(resource.military_time(zone)).to eq('05:30:45')
      end
    end

    context 'when absolute_time exists but zone does not exist' do
      it 'returns the entered_time in hh:mm:ss format' do
        resource = build_stubbed(model_name, absolute_time: '2017-07-31 09:30:45 -0000', entered_time: '0123')
        zone = nil
        expect(resource.military_time(zone)).to eq('01:23:00')
      end
    end

    context 'when no absolute_time exists' do
      it 'returns the entered_time in hh:mm:ss format' do
        resource = build_stubbed(model_name, absolute_time: nil, entered_time: '16:30:45')
        expect(resource.military_time).to eq('16:30:45')
      end
    end

    context 'when entered_time has no colons' do
      it 'returns the entered_time in hh:mm:ss format' do
        resource = build_stubbed(model_name, absolute_time: nil, entered_time: '163045')
        expect(resource.military_time).to eq('16:30:45')
      end
    end
  end

  describe '#sub_split_kind' do
    context 'when bitkey is the in_bitkey' do
      let(:live_time) { LiveTime.new(bitkey: in_bitkey) }

      it 'returns "in" when bitkey is the in_bitkey' do
        expect(live_time.sub_split_kind).to eq('In')
      end
    end

    context 'when bitkey is the out_bitkey' do
      let(:live_time) { LiveTime.new(bitkey: out_bitkey) }

      it 'returns "in" when bitkey is the in_bitkey' do
        expect(live_time.sub_split_kind).to eq('Out')
      end
    end
  end

  describe '#sub_split_kind=' do
    context 'when sub_split_kind is "in"' do
      let(:sub_split_kind) { 'in' }

      it 'sets the bitkey to the in_bitkey' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(in_bitkey)
      end
    end

    context 'when sub_split_kind is "out"' do
      let(:sub_split_kind) { 'out' }

      it 'sets the bitkey to the in_bitkey' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(out_bitkey)
      end
    end

    context 'when sub_split_kind has different capitalization' do
      let(:sub_split_kind) { 'OUT' }

      it 'sets the bitkey as expected' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(out_bitkey)
      end
    end

    context 'when sub_split_kind is a symbol' do
      let(:sub_split_kind) { :out }

      it 'sets the bitkey as expected' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(out_bitkey)
      end
    end

    context 'when sub_split_kind is an empty string' do
      let(:sub_split_kind) { '' }

      it 'sets the bitkey to nil' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(nil)
      end
    end

    context 'when sub_split_kind is nil' do
      let(:sub_split_kind) { nil }

      it 'sets the bitkey to nil' do
        live_time = LiveTime.new(sub_split_kind: sub_split_kind)
        expect(live_time.bitkey).to eq(nil)
      end
    end
  end
end
