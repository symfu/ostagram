require 'rails_helper'

RSpec.describe DebHelper, type: :helper do
  let(:log_file_path) { Rails.root.join('tmp', '_deb.log') }
  let(:prefix_log_file_path) { Rails.root.join('tmp', 'custom_deb.log') }

  before(:each) do
    File.delete(log_file_path) if File.exist?(log_file_path)
    File.delete(prefix_log_file_path) if File.exist?(prefix_log_file_path)
  end

  after(:each) do
    File.delete(log_file_path) if File.exist?(log_file_path)
    File.delete(prefix_log_file_path) if File.exist?(prefix_log_file_path)
  end

  describe '#write_log' do
    context 'when writing log without prefix' do
      it 'creates log file in tmp directory' do
        helper.write_log('Test log message')
        expect(File.exist?(log_file_path)).to be true
      end

      it 'writes log message with timestamp' do
        helper.write_log('Test log message')
        log_content = File.read(log_file_path)
        expect(log_content).to include('Test log message')
        expect(log_content).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'appends multiple log entries' do
        helper.write_log('First message')
        helper.write_log('Second message')
        
        log_content = File.read(log_file_path)
        expect(log_content.lines.count).to eq(2)
        expect(log_content).to include('First message')
        expect(log_content).to include('Second message')
      end

      it 'handles empty string message' do
        helper.write_log('')
        log_content = File.read(log_file_path)
        expect(log_content).to include('] ')
        expect(log_content).to end_with("\n")
      end

      it 'handles nil message' do
        helper.write_log(nil)
        log_content = File.read(log_file_path)
        expect(log_content).to include('] ')
        expect(log_content).to end_with("\n")
      end

      it 'handles special characters in message' do
        special_message = 'Special chars: !@#$%^&*()_+-=[]{}|;:,.<>?'
        helper.write_log(special_message)
        log_content = File.read(log_file_path)
        expect(log_content).to include(special_message)
      end

      it 'handles multiline message' do
        multiline_message = "Line 1\nLine 2\nLine 3"
        helper.write_log(multiline_message)
        log_content = File.read(log_file_path)
        expect(log_content).to include('Line 1')
        expect(log_content).to include('Line 2')
        expect(log_content).to include('Line 3')
      end
    end

    context 'when writing log with prefix' do
      it 'creates log file with custom prefix' do
        helper.write_log('Test log message', 'custom')
        expect(File.exist?(prefix_log_file_path)).to be true
      end

      it 'writes log message with timestamp and custom prefix' do
        helper.write_log('Test log message', 'custom')
        log_content = File.read(prefix_log_file_path)
        expect(log_content).to include('Test log message')
        expect(log_content).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
      end

      it 'handles empty prefix' do
        helper.write_log('Test message', '')
        empty_prefix_path = Rails.root.join('tmp', '_deb.log')
        expect(File.exist?(empty_prefix_path)).to be true
      end

      it 'handles nil prefix' do
        helper.write_log('Test message', nil)
        nil_prefix_path = Rails.root.join('tmp', '_deb.log')
        
        expect(File.exist?(nil_prefix_path)).to be true
        
        File.delete(nil_prefix_path) if File.exist?(nil_prefix_path)
      end

      it 'handles prefix with special characters' do
        special_prefix = 'test-123_456'
        special_prefix_path = Rails.root.join('tmp', "#{special_prefix}_deb.log")
        
        helper.write_log('Test message', special_prefix)
        expect(File.exist?(special_prefix_path)).to be true
        
        File.delete(special_prefix_path) if File.exist?(special_prefix_path)
      end

      it 'handles prefix with spaces' do
        space_prefix = 'test prefix'
        space_prefix_path = Rails.root.join('tmp', "#{space_prefix}_deb.log")
        
        helper.write_log('Test message', space_prefix)
        expect(File.exist?(space_prefix_path)).to be true
        
        File.delete(space_prefix_path) if File.exist?(space_prefix_path)
      end
    end

    context 'when writing log with different data types' do
      it 'handles numeric message' do
        helper.write_log(123)
        log_content = File.read(log_file_path)
        expect(log_content).to include('123')
      end

      it 'handles boolean message' do
        helper.write_log(true)
        log_content = File.read(log_file_path)
        expect(log_content).to include('true')
      end

      it 'handles symbol message' do
        helper.write_log(:test_symbol)
        log_content = File.read(log_file_path)
        expect(log_content).to include('test_symbol')
      end

      it 'handles hash message' do
        hash_message = { key: 'value', number: 42 }
        helper.write_log(hash_message)
        log_content = File.read(log_file_path)
        expect(log_content).to include('{:key=>"value", :number=>42}')
      end

      it 'handles array message' do
        array_message = [1, 2, 3, 'test']
        helper.write_log(array_message)
        log_content = File.read(log_file_path)
        expect(log_content).to include('[1, 2, 3, "test"]')
      end
    end

    context 'file operations' do
      it 'appends to existing log file' do
        File.write(log_file_path, "Existing log entry\n")
        
        helper.write_log('New log entry')
        
        log_content = File.read(log_file_path)
        expect(log_content.lines.count).to eq(2)
        expect(log_content).to include('Existing log entry')
        expect(log_content).to include('New log entry')
      end

      it 'handles file permissions correctly' do
        helper.write_log('Test message')
        expect(File.readable?(log_file_path)).to be true
        expect(File.writable?(log_file_path)).to be true
      end
    end

    context 'timestamp format' do
      it 'uses correct timestamp format' do
        helper.write_log('Test message')
        
        log_content = File.read(log_file_path)
        timestamp_match = log_content.match(/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/)
        expect(timestamp_match).to be_truthy
        
        log_time = Time.parse(timestamp_match[1])
        current_time = Time.now
        
        expect(log_time).to be_within(5.seconds).of(current_time)
      end

      it 'includes timestamp in every log entry' do
        helper.write_log('Message 1')
        helper.write_log('Message 2')
        helper.write_log('Message 3')
        
        log_content = File.read(log_file_path)
        lines = log_content.lines
        
        lines.each do |line|
          expect(line).to match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        end
      end
    end

    context 'log file naming convention' do
      it 'follows naming pattern: prefix_deb.log' do
        helper.write_log('Test message', 'myapp')
        expected_path = Rails.root.join('tmp', 'myapp_deb.log')
        expect(File.exist?(expected_path)).to be true
        
        File.delete(expected_path) if File.exist?(expected_path)
      end

      it 'uses default naming when no prefix provided' do
        helper.write_log('Test message')
        expected_path = Rails.root.join('tmp', '_deb.log')
        expect(File.exist?(expected_path)).to be true
      end
    end
  end
end
