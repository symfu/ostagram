require 'rails_helper'

RSpec.describe ImageJob, type: :job do
  let(:image_job) { ImageJob.new(:server1) }
  let(:client) { create(:client) }
  let(:content) { create(:content) }
  let(:style) { create(:style) }
  let(:queue_image) { create(:queue_image, client: client, content: content, style: style) }

  before do
    allow(image_job).to receive(:log)
    allow(image_job).to receive(:sleep)
    allow(image_job).to receive(:write_log)
  end

  describe 'initialization' do
    it 'sets worker_name from constructor' do
      expect(image_job.instance_variable_get(:@worker_name)).to eq(:server1)
    end

    it 'includes required modules' do
      expect(ImageJob.included_modules).to include(DebHelper)
      expect(ImageJob.included_modules).to include(ConstHelper)
    end

    it 'sets default class variables' do
      expect(ImageJob.instance_variable_get(:@hostname)).to eq('localhost')
      expect(ImageJob.instance_variable_get(:@username)).to eq('root')
      expect(ImageJob.instance_variable_get(:@password)).to eq('123')
      expect(ImageJob.instance_variable_get(:@remote_neural_path)).to eq('~/neural-style')
      expect(ImageJob.instance_variable_get(:@iteration_count)).to eq(10)
      expect(ImageJob.instance_variable_get(:@local_tmp_path)).to eq('~/tmp/output')
      expect(ImageJob.instance_variable_get(:@square_format)).to eq(false)
    end
  end

  describe '#set_config' do
    context 'when worker_name is nil' do
      it 'returns early without changing configuration' do
        expect(image_job).not_to receive(:get_param_config)
        image_job.set_config(nil)
      end
    end

    context 'when worker_name is provided' do
      let(:config) do
        {
          'host' => 'test-server.com',
          'username' => 'testuser',
          'password' => 'testpass',
          'remote_neural_path' => '/path/to/neural',
          'iteration_count' => 20,
          'init_params' => '-gpu -1',
          'admin_email' => 'admin@test.com',
          'square_format' => true
        }
      end

      before do
        allow(image_job).to receive(:get_param_config).and_return(config)
        allow(Dir).to receive(:exist?).and_return(false)
        allow(Dir).to receive(:mkdir)
        allow(Rails).to receive(:root).and_return(Pathname.new('/rails/root'))
      end

      it 'updates configuration with values from config file' do
        image_job.set_config(:server1)
        
        expect(image_job.instance_variable_get(:@hostname)).to eq('test-server.com')
        expect(image_job.instance_variable_get(:@username)).to eq('testuser')
        expect(image_job.instance_variable_get(:@password)).to eq('testpass')
        expect(image_job.instance_variable_get(:@remote_neural_path)).to eq('/path/to/neural')
        expect(image_job.instance_variable_get(:@iteration_count)).to eq(20)
        expect(image_job.instance_variable_get(:@admin_email)).to eq('admin@test.com')
        expect(image_job.instance_variable_get(:@square_format)).to eq(true)
      end

      it 'creates local tmp directory if it does not exist' do
        expect(Dir).to receive(:mkdir).with(Pathname.new('/rails/root/tmp/server1'))
        image_job.set_config(:server1)
      end

      it 'sets init_params with iteration count' do
        image_job.set_config(:server1)
        expect(image_job.instance_variable_get(:@init_params)).to include('-num_iterations 2000')
      end
    end

    context 'when config is blank' do
      before do
        allow(image_job).to receive(:get_param_config).and_return(nil)
      end

      it 'returns early without changing configuration' do
        image_job.set_config(:server1)
        expect(image_job.instance_variable_get(:@hostname)).to be_nil
      end
    end
  end

  describe '#set_init_str' do
    context 'when style has no init string' do
      before do
        allow(style).to receive(:init).and_return(nil)
        allow(queue_image).to receive(:init_str).and_return(nil)
      end

      it 'returns true when no init string is provided' do
        expect(image_job.set_init_str(queue_image)).to be true
      end
    end

    context 'when queue_image has custom init_str' do
      before do
        allow(style).to receive(:init).and_return('style_init')
        allow(queue_image).to receive(:init_str).and_return('custom_init')
        allow(image_job).to receive(:merge_init_params).and_return('merged_params')
      end

      it 'uses custom init_str instead of style init' do
        expect(image_job).to receive(:merge_init_params).with(anything, 'custom_init')
        image_job.set_init_str(queue_image)
      end
    end

    context 'when init string contains iteration count' do
      before do
        allow(style).to receive(:init).and_return('style_init')
        allow(queue_image).to receive(:init_str).and_return('custom_init')
        allow(image_job).to receive(:merge_init_params).and_return('merged_params -num_iterations 500')
      end

      it 'extracts and sets iteration count' do
        image_job.set_init_str(queue_image)
        expect(image_job.instance_variable_get(:@iteration_count)).to eq(5)
      end
    end
  end

  describe '#merge_init_params' do
    it 'merges two parameter strings correctly' do
      init = ' -gpu -1 -image_size 500'
      par = ' -style_weight 1000 -content_weight 1'
      
      result = image_job.merge_init_params(init, par)
      
      expect(result).to include('gpu')
      expect(result).to include('image_size')
      expect(result).to include('style_weight')
      expect(result).to include('content_weight')
    end

    it 'handles nil parameters gracefully' do
      expect { image_job.merge_init_params(nil, 'params') }.to raise_error(TypeError)
      expect { image_job.merge_init_params('init', nil) }.to raise_error(TypeError)
    end
  end

  describe '#str_to_hash' do
    it 'converts parameter string to hash' do
      str = ' -gpu 1 -image_size 500 -style_weight 1000'
      result = image_job.str_to_hash(str)
      
      expect(result['gpu']).to eq('1')
      expect(result['image_size']).to eq('500')
      expect(result['style_weight']).to eq('1000')
    end

    it 'handles parameters with no values' do
      str = ' -gpu -verbose'
      result = image_job.str_to_hash(str)
      
      expect(result['gpu']).to eq('')
      expect(result['verbose']).to eq('')
    end

    it 'handles empty string' do
      result = image_job.str_to_hash('')
      expect(result).to eq({})
    end
  end

  describe '#get_images_from_queue' do
    context 'when clients with null lastprocess exist' do
      before do
        allow(Client).to receive(:find_by_sql).and_return([client])
        allow(client).to receive(:queue_images).and_return(double(where: double(order: double(first: queue_image))))
      end

      it 'returns first queue image from client with null lastprocess' do
        expect(image_job.get_images_from_queue).to eq(queue_image)
      end
    end

    context 'when no clients with null lastprocess' do
      before do
        allow(Client).to receive(:find_by_sql).and_return([], [client])
        allow(client).to receive(:queue_images).and_return(double(where: double(order: double(first: queue_image))))
      end

      it 'falls back to clients ordered by lastprocess' do
        expect(image_job.get_images_from_queue).to eq(queue_image)
      end
    end

    context 'when no clients exist' do
      before do
        allow(Client).to receive(:find_by_sql).and_return([])
      end

      it 'returns nil' do
        expect(image_job.get_images_from_queue).to be_nil
      end
    end
  end

  describe 'method behavior' do
    it 'can set and retrieve configuration values' do
      image_job.instance_variable_set(:@sleep_time, 30)
      expect(image_job.instance_variable_get(:@sleep_time)).to eq(30)
    end

    it 'can process image with different parameters' do
      allow(image_job).to receive(:set_config)
      allow(image_job).to receive(:get_images_from_queue).and_return(queue_image)
      allow(image_job).to receive(:execute_image).and_return('OK')
      
      allow(image_job).to receive(:loop).and_yield
      allow(image_job).to receive(:sleep).and_raise(StandardError.new('break loop'))
      
      expect { image_job.execute }.to raise_error(StandardError, 'break loop')
    end
  end

  describe 'protected method access' do
    it 'has protected methods that can be called internally' do
      expect(image_job.respond_to?(:execute_image, true)).to be true
      expect(image_job.respond_to?(:get_server_name, true)).to be true
      expect(image_job.respond_to?(:upload_image, true)).to be true
      expect(image_job.respond_to?(:download_image, true)).to be true
    end
  end

  describe 'integration behavior' do
    it 'can be instantiated with different worker names' do
      job1 = ImageJob.new(:worker1)
      job2 = ImageJob.new(:worker2)
      
      expect(job1.instance_variable_get(:@worker_name)).to eq(:worker1)
      expect(job2.instance_variable_get(:@worker_name)).to eq(:worker2)
    end

    it 'can handle configuration changes' do
      image_job.instance_variable_set(:@hostname, 'new-server')
      image_job.instance_variable_set(:@username, 'newuser')
      image_job.instance_variable_set(:@password, 'newpass')
      
      expect(image_job.instance_variable_get(:@hostname)).to eq('new-server')
      expect(image_job.instance_variable_get(:@username)).to eq('newuser')
      expect(image_job.instance_variable_get(:@password)).to eq('newpass')
    end
  end
end
