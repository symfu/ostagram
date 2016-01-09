require 'rails_helper'

RSpec.describe WorkerHelper, type: :helper do
  describe '#start_workers' do
    context 'when Resque queue is empty' do
      it 'enqueues ResqueJob with server1 worker name' do
        allow(Resque).to receive(:size).with(:server1).and_return(0)
        expect(Resque).to receive(:enqueue).with(ResqueJob, :server1)
        helper.start_workers
      end
    end

    context 'when Resque queue has items' do
      it 'does not enqueue ResqueJob when queue is not empty' do
        allow(Resque).to receive(:size).with(:server1).and_return(5)
        expect(Resque).not_to receive(:enqueue)
        helper.start_workers
      end
    end

    context 'when Resque operations raise an error' do
      it 'logs error message and continues execution' do
        error = StandardError.new('Resque connection failed')
        allow(Resque).to receive(:size).and_raise(error)
        expect(Rails.logger).to receive(:error).with('Error starting workers: Resque connection failed')
        expect { helper.start_workers }.not_to raise_error
      end
    end

    context 'when Resque.size raises specific errors' do
      it 'handles Redis connection errors gracefully' do
        redis_error = Redis::CannotConnectError.new('Connection refused')
        allow(Resque).to receive(:size).and_raise(redis_error)
        expect(Rails.logger).to receive(:error).with('Error starting workers: Connection refused')
        expect { helper.start_workers }.not_to raise_error
      end

      it 'handles timeout errors gracefully' do
        timeout_error = Timeout::Error.new('Operation timed out')
        allow(Resque).to receive(:size).and_raise(timeout_error)
        expect(Rails.logger).to receive(:error).with('Error starting workers: Operation timed out')
        expect { helper.start_workers }.not_to raise_error
      end
    end
  end

  describe '#start_bot' do
    context 'when Resque queue is empty' do
      it 'enqueues BotResqueJob with bot1 worker name' do
        allow(Resque).to receive(:size).with(:bot1).and_return(0)
        expect(Resque).to receive(:enqueue).with(BotResqueJob, :bot1)
        helper.start_bot
      end
    end

    context 'when Resque queue has items' do
      it 'does not enqueue BotResqueJob when queue is not empty' do
        allow(Resque).to receive(:size).with(:bot1).and_return(3)
        expect(Resque).not_to receive(:enqueue)
        helper.start_bot
      end
    end

    context 'when Resque queue has exactly one item' do
      it 'does not enqueue BotResqueJob when queue has one item' do
        allow(Resque).to receive(:size).with(:bot1).and_return(1)
        expect(Resque).not_to receive(:enqueue)
        helper.start_bot
      end
    end

    context 'when Resque operations raise an error' do
      it 'raises the error without error handling' do
        error = StandardError.new('Resque connection failed')
        allow(Resque).to receive(:size).and_raise(error)
        expect { helper.start_bot }.to raise_error(StandardError, 'Resque connection failed')
      end
    end

    context 'when Resque.size raises specific errors' do
      it 'propagates Redis connection errors' do
        redis_error = Redis::CannotConnectError.new('Connection refused')
        allow(Resque).to receive(:size).and_raise(redis_error)
        expect { helper.start_bot }.to raise_error(Redis::CannotConnectError, 'Connection refused')
      end

      it 'propagates timeout errors' do
        timeout_error = Timeout::Error.new('Operation timed out')
        allow(Resque).to receive(:size).and_raise(timeout_error)
        expect { helper.start_bot }.to raise_error(Timeout::Error, 'Operation timed out')
      end
    end
  end

  describe 'worker name constants' do
    context 'server worker' do
      it 'uses :server1 as worker name for start_workers' do
        allow(Resque).to receive(:size).with(:server1).and_return(0)
        expect(Resque).to receive(:enqueue).with(ResqueJob, :server1)
        helper.start_workers
      end
    end

    context 'bot worker' do
      it 'uses :bot1 as worker name for start_bot' do
        allow(Resque).to receive(:size).with(:bot1).and_return(0)
        expect(Resque).to receive(:enqueue).with(BotResqueJob, :bot1)
        helper.start_bot
      end
    end
  end
end
