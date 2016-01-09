require 'rails_helper'

RSpec.describe BotJob, type: :job do
  let(:bot_job) { BotJob.new }
  let(:admin_client) { create(:client, email: 'xxx@gmail.com') }
  let(:content) { create(:content, status: ConstHelper::BOT_CONTENT_IMAGE) }
  let(:style) { create(:style, status: ConstHelper::BOT_STYLE_IMAGE) }

  before do
    bot_job.instance_variable_set(:@admin, admin_client)
    allow(bot_job).to receive(:log)
    allow(bot_job).to receive(:sleep)
    allow(bot_job).to receive(:start_workers)
  end

  describe 'initialization' do
    context 'when creating a new instance' do
      it 'sets default configuration values' do
        expect(bot_job.instance_variable_get(:@worker_name)).to eq(:bot1)
        expect(bot_job.instance_variable_get(:@admin_email)).to eq('xxx@gmail.com')
        expect(bot_job.instance_variable_get(:@sleep_time)).to eq(10)
        expect(bot_job.instance_variable_get(:@end_status)).to eq(11)
        expect(bot_job.instance_variable_get(:@debug)).to eq(true)
      end

      it 'includes required modules' do
        expect(BotJob.included_modules).to include(DebHelper)
        expect(BotJob.included_modules).to include(ConstHelper)
        expect(BotJob.included_modules).to include(WorkerHelper)
      end
    end
  end

  describe '#set_config' do
    context 'when bot_name is nil' do
      it 'returns early without changing configuration' do
        expect(bot_job).not_to receive(:load_settings)
        bot_job.set_config(nil)
      end
    end

    context 'when bot_name is provided' do
      let(:config_params) do
        {
          'bot1' => {
            'admin_email' => 'admin@example.com',
            'sleep_time' => 20,
            'user_priority' => true,
            'end_status' => 15,
            'debug' => false,
            'with_init_params' => false
          }
        }
      end

      before do
        allow(bot_job).to receive(:load_settings).and_return(config_params)
        allow(Client).to receive(:find_by_email).and_return(admin_client)
      end

      it 'updates configuration with values from config file' do
        bot_job.set_config(:bot1)
        
        expect(bot_job.instance_variable_get(:@worker_name)).to eq(:bot1)
        expect(bot_job.instance_variable_get(:@admin_email)).to eq('admin@example.com')
        expect(bot_job.instance_variable_get(:@sleep_time)).to eq(20)
        expect(bot_job.instance_variable_get(:@user_priority)).to eq(true)
        expect(bot_job.instance_variable_get(:@end_status)).to eq(15)
        expect(bot_job.instance_variable_get(:@debug)).to eq(false)
        expect(bot_job.instance_variable_get(:@with_init_params)).to eq(false)
      end

      it 'sets admin client' do
        expect(Client).to receive(:find_by_email).with('admin@example.com')
        bot_job.set_config(:bot1)
        expect(bot_job.instance_variable_get(:@admin)).to eq(admin_client)
      end

      context 'when with_init_params is true' do
        let(:config_params_with_init) do
          {
            'bot1' => {
              'admin_email' => 'admin@example.com',
              'sleep_time' => 20,
              'user_priority' => true,
              'end_status' => 15,
              'debug' => false,
              'with_init_params' => true,
              'init_params' => { 'param1' => 'value1', 'param2' => 'value2' }
            }
          }
        end

        before do
          allow(bot_job).to receive(:load_settings).and_return(config_params_with_init)
        end

        it 'sets init_params array' do
          bot_job.set_config(:bot1)
          expect(bot_job.instance_variable_get(:@init_params)).to eq(['value1', 'value2'])
        end
      end
    end

    context 'when config file is blank' do
      before do
        allow(bot_job).to receive(:load_settings).and_return({})
      end

      it 'returns early without changing configuration' do
        bot_job.set_config(:bot1)
        expect(bot_job.instance_variable_get(:@admin_email)).to eq('xxx@gmail.com')
      end
    end
  end

  describe '#create_queue' do
    it 'creates a new QueueImage with correct attributes' do
      new_queue_image = QueueImage.new
      allow(QueueImage).to receive(:new).and_return(new_queue_image)
      allow(new_queue_image).to receive(:save)
      
      bot_job.create_queue(content, style, 'init_string')
      
      expect(new_queue_image.status).to eq(ConstHelper::STATUS_NOT_PROCESSED)
      expect(new_queue_image.end_status).to eq(11)
      expect(new_queue_image.content_id).to eq(content.id)
      expect(new_queue_image.style_id).to eq(style.id)
      expect(new_queue_image.init_str).to eq('init_string')
      expect(new_queue_image.client_id).to eq(admin_client.id)
    end
  end

  describe 'private methods' do
    describe '#check_idle' do
      context 'when user_priority is true' do
        before do
          bot_job.instance_variable_set(:@user_priority, true)
        end

        it 'checks for any not processed or in process items' do
          queue_double = double('QueueImage')
          allow(QueueImage).to receive(:where).with("status = #{ConstHelper::STATUS_NOT_PROCESSED} or status = #{ConstHelper::STATUS_IN_PROCESS}").and_return(queue_double)
          allow(queue_double).to receive(:count).and_return(0)
          bot_job.send(:check_idle)
        end
      end

      context 'when user_priority is false' do
        before do
          bot_job.instance_variable_set(:@user_priority, false)
        end

        it 'checks only for admin items' do
          queue_double = double('QueueImage')
          allow(QueueImage).to receive(:where).with("client_id = #{admin_client.id} and status = #{ConstHelper::STATUS_NOT_PROCESSED}").and_return(queue_double)
          allow(queue_double).to receive(:count).and_return(0)
          bot_job.send(:check_idle)
        end
      end

      it 'returns true when queue is empty' do
        queue_double = double('QueueImage')
        allow(QueueImage).to receive(:where).and_return(queue_double)
        allow(queue_double).to receive(:count).and_return(0)
        expect(bot_job.send(:check_idle)).to be true
      end

      it 'returns false when queue has items' do
        queue_double = double('QueueImage')
        allow(QueueImage).to receive(:where).and_return(queue_double)
        allow(queue_double).to receive(:count).and_return(1)
        expect(bot_job.send(:check_idle)).to be false
      end
    end

    describe '#get_random_style' do
      it 'returns a random style with BOT_STYLE_IMAGE status' do
        styles_double = double('Style')
        allow(Style).to receive(:where).with(status: ConstHelper::BOT_STYLE_IMAGE).and_return(styles_double)
        allow(styles_double).to receive(:count).and_return(0)
        bot_job.send(:get_random_style)
      end

      it 'returns nil when no styles are available' do
        styles_double = double('Style')
        allow(Style).to receive(:where).with(status: ConstHelper::BOT_STYLE_IMAGE).and_return(styles_double)
        allow(styles_double).to receive(:count).and_return(0)
        expect(bot_job.send(:get_random_style)).to be_nil
      end

      it 'returns a random style when styles are available' do
        styles_double = double('Style')
        allow(Style).to receive(:where).with(status: ConstHelper::BOT_STYLE_IMAGE).and_return(styles_double)
        allow(styles_double).to receive(:count).and_return(1)
        allow(styles_double).to receive(:[]).with(0).and_return(style)
        
        expect(bot_job.send(:get_random_style)).to eq(style)
      end
    end

    describe '#get_random_content' do
      it 'returns a random content with BOT_CONTENT_IMAGE status' do
        contents_double = double('Content')
        allow(Content).to receive(:where).with(status: ConstHelper::BOT_CONTENT_IMAGE).and_return(contents_double)
        allow(contents_double).to receive(:count).and_return(0)
        bot_job.send(:get_random_content)
      end

      it 'returns nil when no content is available' do
        contents_double = double('Content')
        allow(Content).to receive(:where).with(status: ConstHelper::BOT_CONTENT_IMAGE).and_return(contents_double)
        allow(contents_double).to receive(:count).and_return(0)
        expect(bot_job.send(:get_random_content)).to be_nil
      end

      it 'returns a random content when content is available' do
        contents_double = double('Content')
        allow(Content).to receive(:where).with(status: ConstHelper::BOT_CONTENT_IMAGE).and_return(contents_double)
        allow(contents_double).to receive(:count).and_return(1)
        allow(contents_double).to receive(:[]).with(0).and_return(content)
        
        expect(bot_job.send(:get_random_content)).to eq(content)
      end
    end

    describe '#log method' do
      it 'calls write_log when debug is enabled' do
        expect { bot_job.send(:log, 'test message') }.not_to raise_error
      end

      context 'when debug is disabled' do
        before do
          bot_job.instance_variable_set(:@debug, false)
        end

        it 'can be called without error' do
          expect { bot_job.send(:log, 'test message') }.not_to raise_error
        end
      end
    end
  end

  describe 'method behavior' do
    it 'can set and retrieve configuration values' do
      bot_job.instance_variable_set(:@sleep_time, 30)
      expect(bot_job.instance_variable_get(:@sleep_time)).to eq(30)
    end

    it 'can create queue items with different parameters' do
      new_queue_image = QueueImage.new
      allow(QueueImage).to receive(:new).and_return(new_queue_image)
      allow(new_queue_image).to receive(:save)
      
      bot_job.create_queue(content, style, nil)
      expect(new_queue_image.init_str).to be_nil
      
      bot_job.create_queue(content, style, 'custom_param')
      expect(new_queue_image.init_str).to eq('custom_param')
    end
  end
end
