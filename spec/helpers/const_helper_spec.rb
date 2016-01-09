require 'rails_helper'

RSpec.describe ConstHelper, type: :helper do
  describe '#get_queue_item_status' do
    let(:mock_item) { double('item') }

    context 'when status is STATUS_DELETED' do
      it 'returns "Deleted"' do
        allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_DELETED)
        expect(helper.get_queue_item_status(mock_item)).to eq('Deleted')
      end
    end

    context 'when status is STATUS_ERROR' do
      it 'returns "Error during processing"' do
        allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_ERROR)
        expect(helper.get_queue_item_status(mock_item)).to eq('Error during processing')
      end
    end

    context 'when status is STATUS_HIDDEN' do
      it 'returns "Hidden"' do
        allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_HIDDEN)
        expect(helper.get_queue_item_status(mock_item)).to eq('Hidden')
      end
    end

    context 'when status is STATUS_NOT_PROCESSED' do
      it 'returns "Waiting for processing"' do
        allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_NOT_PROCESSED)
        expect(helper.get_queue_item_status(mock_item)).to eq('Waiting for processing')
      end
    end

    context 'when status is STATUS_IN_PROCESS' do
      it 'returns "Processing"' do
        allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_IN_PROCESS)
        expect(helper.get_queue_item_status(mock_item)).to eq('Processing')
      end
    end

    context 'when status is STATUS_PROCESSED' do
      context 'when ptime is present' do
        it 'returns processed message with time' do
          time = Time.new(2023, 1, 1, 14, 30, 45)
          allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_PROCESSED)
          allow(mock_item).to receive(:ptime).and_return(time)
          expect(helper.get_queue_item_status(mock_item)).to eq('Processed in 14:30:45')
        end
      end

      context 'when ptime is nil' do
        it 'returns processed message without time' do
          allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_PROCESSED)
          allow(mock_item).to receive(:ptime).and_return(nil)
          expect(helper.get_queue_item_status(mock_item)).to eq('Processed in ')
        end
      end
    end

    context 'when status is STATUS_PROCESSED_BY_BOT' do
      context 'when ptime is present' do
        it 'returns bot processed message with time' do
          time = Time.new(2023, 1, 1, 15, 45, 30)
          allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_PROCESSED_BY_BOT)
          allow(mock_item).to receive(:ptime).and_return(time)
          expect(helper.get_queue_item_status(mock_item)).to eq('Processed by bot in 15:45:30')
        end
      end

      context 'when ptime is nil' do
        it 'returns bot processed message without time' do
          allow(mock_item).to receive(:status).and_return(ConstHelper::STATUS_PROCESSED_BY_BOT)
          allow(mock_item).to receive(:ptime).and_return(nil)
          expect(helper.get_queue_item_status(mock_item)).to eq('Processed by bot in ')
        end
      end
    end

    context 'when status is unknown' do
      it 'returns nil for unknown status' do
        allow(mock_item).to receive(:status).and_return(999)
        expect(helper.get_queue_item_status(mock_item)).to be_nil
      end
    end
  end
end
