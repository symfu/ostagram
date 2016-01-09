require 'rails_helper'

RSpec.describe BotResqueJob, type: :job do
  describe 'class methods' do
    describe '.perform' do
      context 'when called with arguments' do
        it 'creates a new BotJob instance' do
          expect(BotJob).to receive(:new).and_return(double(execute: true))
          BotResqueJob.perform('arg1', 'arg2')
        end

        it 'calls execute on the BotJob instance' do
          bot_job_double = double('BotJob')
          expect(BotJob).to receive(:new).and_return(bot_job_double)
          expect(bot_job_double).to receive(:execute)
          BotResqueJob.perform('arg1', 'arg2')
        end

        it 'ignores the arguments passed to perform' do
          bot_job_double = double('BotJob')
          expect(BotJob).to receive(:new).and_return(bot_job_double)
          expect(bot_job_double).to receive(:execute)
          BotResqueJob.perform('any', 'arguments', 'here')
        end
      end

      context 'when called without arguments' do
        it 'creates a new BotJob instance' do
          expect(BotJob).to receive(:new).and_return(double(execute: true))
          BotResqueJob.perform
        end

        it 'calls execute on the BotJob instance' do
          bot_job_double = double('BotJob')
          expect(BotJob).to receive(:new).and_return(bot_job_double)
          expect(bot_job_double).to receive(:execute)
          BotResqueJob.perform
        end
      end
    end
  end

  describe 'queue configuration' do
    it 'sets the queue to :job1' do
      expect(BotResqueJob.instance_variable_get(:@queue)).to eq(:job1)
    end
  end

  describe 'initialization' do
    it 'can be instantiated' do
      expect { BotResqueJob.new }.not_to raise_error
    end

    it 'creates a valid instance' do
      expect(BotResqueJob.new).to be_a(BotResqueJob)
    end
  end
end
