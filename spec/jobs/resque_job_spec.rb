require 'rails_helper'

RSpec.describe ResqueJob, type: :job do
  describe 'class methods' do
    describe '.perform' do
      context 'when called with arguments' do
        it 'creates a new ImageJob instance' do
          expect(ImageJob).to receive(:new).with(:server1).and_return(double(execute: true))
          ResqueJob.perform('arg1', 'arg2')
        end

        it 'calls execute on the ImageJob instance' do
          image_job_double = double('ImageJob')
          expect(ImageJob).to receive(:new).with(:server1).and_return(image_job_double)
          expect(image_job_double).to receive(:execute)
          ResqueJob.perform('arg1', 'arg2')
        end

        it 'ignores the arguments passed to perform' do
          image_job_double = double('ImageJob')
          expect(ImageJob).to receive(:new).with(:server1).and_return(image_job_double)
          expect(image_job_double).to receive(:execute)
          ResqueJob.perform('any', 'arguments', 'here')
        end
      end

      context 'when called without arguments' do
        it 'creates a new ImageJob instance' do
          expect(ImageJob).to receive(:new).with(:server1).and_return(double(execute: true))
          ResqueJob.perform
        end

        it 'calls execute on the ImageJob instance' do
          image_job_double = double('ImageJob')
          expect(ImageJob).to receive(:new).with(:server1).and_return(image_job_double)
          expect(image_job_double).to receive(:execute)
          ResqueJob.perform
        end
      end
    end
  end

  describe 'queue configuration' do
    it 'sets the queue to :server1' do
      expect(ResqueJob.instance_variable_get(:@queue)).to eq(:server1)
    end
  end

  describe 'initialization' do
    it 'can be instantiated' do
      expect { ResqueJob.new }.not_to raise_error
    end

    it 'creates a valid instance' do
      expect(ResqueJob.new).to be_a(ResqueJob)
    end
  end
end
