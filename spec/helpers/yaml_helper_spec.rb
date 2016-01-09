require 'rails_helper'

RSpec.describe YamlHelper, type: :helper do
  let(:temp_file_path) { Rails.root.join('tmp', 'test_config.yml') }
  let(:sample_config) do
    {
      'database' => {
        'host' => 'localhost',
        'port' => '5432'
      },
      'redis' => {
        'url' => 'redis://localhost:6379'
      }
    }
  end

  before(:each) do
    File.delete(temp_file_path) if File.exist?(temp_file_path)
  end

  after(:each) do
    File.delete(temp_file_path) if File.exist?(temp_file_path)
  end

  describe '#load_settings' do
    context 'when file exists' do
      before(:each) do
        File.write(temp_file_path, sample_config.to_yaml)
      end

      it 'loads and returns YAML configuration' do
        result = helper.load_settings(temp_file_path)
        expect(result).to eq(sample_config)
      end

      it 'caches configuration in @config instance variable' do
        helper.load_settings(temp_file_path)
        expect(helper.instance_variable_get(:@config)).to eq(sample_config)
      end

      it 'handles nested configuration structures' do
        result = helper.load_settings(temp_file_path)
        expect(result['database']['host']).to eq('localhost')
        expect(result['redis']['url']).to eq('redis://localhost:6379')
      end
    end

    context 'when file does not exist' do
      it 'returns empty hash when file is missing' do
        result = helper.load_settings('nonexistent_file.yml')
        expect(result).to eq({})
      end

      it 'does not set @config when file is missing' do
        helper.load_settings('nonexistent_file.yml')
        expect(helper.instance_variable_get(:@config)).to be_nil
      end
    end

    context 'when file path is nil' do
      it 'raises TypeError for nil file path' do
        expect { helper.load_settings(nil) }.to raise_error(TypeError)
      end
    end
  end

  describe '#get_param_config' do
    before(:each) do
      File.write(temp_file_path, sample_config.to_yaml)
    end

    context 'when keys exist' do
      it 'returns configuration value for existing keys' do
        result = helper.get_param_config(temp_file_path, 'database', 'host')
        expect(result).to eq('localhost')
      end

      it 'handles string keys' do
        result = helper.get_param_config(temp_file_path, 'database', 'port')
        expect(result).to eq('5432')
      end

      it 'converts symbol keys to strings' do
        result = helper.get_param_config(temp_file_path, :database, :host)
        expect(result).to eq('localhost')
      end

      it 'handles mixed key types' do
        result = helper.get_param_config(temp_file_path, 'database', :port)
        expect(result).to eq('5432')
      end
    end

    context 'when keys do not exist' do
      it 'raises NoMethodError for missing first level key' do
        expect { helper.get_param_config(temp_file_path, 'nonexistent', 'host') }.to raise_error(NoMethodError)
      end

      it 'returns nil for missing second level key' do
        result = helper.get_param_config(temp_file_path, 'database', 'nonexistent')
        expect(result).to be_nil
      end
    end

    context 'when file does not exist' do
      it 'raises NoMethodError for nonexistent file' do
        expect { helper.get_param_config('nonexistent.yml', 'database', 'host') }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#update_config' do
    context 'when updating existing configuration' do
      before(:each) do
        File.write(temp_file_path, sample_config.to_yaml)
      end

      it 'updates existing configuration value' do
        helper.update_config(temp_file_path, 'database', 'host', 'newhost')
        updated_config = YAML.load(File.read(temp_file_path))
        expect(updated_config['database']['host']).to eq('newhost')
      end

      it 'converts value to string' do
        helper.update_config(temp_file_path, 'database', 'port', 5433)
        updated_config = YAML.load(File.read(temp_file_path))
        expect(updated_config['database']['port']).to eq('5433')
      end

      it 'preserves other configuration values' do
        helper.update_config(temp_file_path, 'database', 'host', 'newhost')
        updated_config = YAML.load(File.read(temp_file_path))
        expect(updated_config['database']['port']).to eq('5432')
        expect(updated_config['redis']['url']).to eq('redis://localhost:6379')
      end
    end

    context 'when adding new configuration' do
      before(:each) do
        File.write(temp_file_path, sample_config.to_yaml)
      end

      it 'creates new first level key if it does not exist' do
        helper.update_config(temp_file_path, 'new_section', 'key', 'value')
        updated_config = YAML.load(File.read(temp_file_path))
        expect(updated_config['new_section']['key']).to eq('value')
      end

      it 'creates new second level key if first level exists' do
        helper.update_config(temp_file_path, 'database', 'new_key', 'new_value')
        updated_config = YAML.load(File.read(temp_file_path))
        expect(updated_config['database']['new_key']).to eq('new_value')
      end

      it 'converts keys to strings' do
        helper.update_config(temp_file_path, :new_section, :new_key, 'value')
        updated_config = YAML.load(File.read(temp_file_path))
        expect(updated_config['new_section']['new_key']).to eq('value')
      end
    end

    context 'when file does not exist' do
      it 'creates new file with configuration' do
        helper.update_config(temp_file_path, 'new_section', 'key', 'value')
        expect(File.exist?(temp_file_path)).to be true
        
        created_config = YAML.load(File.read(temp_file_path))
        expect(created_config['new_section']['key']).to eq('value')
      end
    end
  end

  describe '#save_settings' do
    context 'when saving configuration' do
      it 'writes configuration to file in YAML format' do
        helper.save_settings(temp_file_path, sample_config)
        expect(File.exist?(temp_file_path)).to be true
        
        saved_config = YAML.load(File.read(temp_file_path))
        expect(saved_config).to eq(sample_config)
      end

      it 'overwrites existing file content' do
        initial_config = { 'old' => 'data' }
        helper.save_settings(temp_file_path, initial_config)
        
        helper.save_settings(temp_file_path, sample_config)
        
        final_config = YAML.load(File.read(temp_file_path))
        expect(final_config).to eq(sample_config)
        expect(final_config).not_to include('old')
      end

      it 'requires directory to exist before saving' do
        nested_path = Rails.root.join('tmp', 'nested', 'dir', 'config.yml')
        
        FileUtils.mkdir_p(File.dirname(nested_path))
        
        helper.save_settings(nested_path, sample_config)
        
        expect(File.exist?(nested_path)).to be true
        saved_config = YAML.load(File.read(nested_path))
        expect(saved_config).to eq(sample_config)
        
        File.delete(nested_path)
        Dir.delete(File.dirname(nested_path))
        Dir.delete(File.dirname(File.dirname(nested_path)))
      end
    end

    context 'when saving empty configuration' do
      it 'saves empty hash as valid YAML' do
        helper.save_settings(temp_file_path, {})
        expect(File.exist?(temp_file_path)).to be true
        
        saved_config = YAML.load(File.read(temp_file_path))
        expect(saved_config).to eq({})
      end
    end
  end

  describe 'integration scenarios' do
    context 'complete configuration workflow' do
      it 'loads, updates, and saves configuration correctly' do
        helper.update_config(temp_file_path, 'app', 'name', 'TestApp')
        helper.update_config(temp_file_path, 'app', 'version', '1.0.0')
        
        saved_config = YAML.load(File.read(temp_file_path))
        expect(saved_config['app']['name']).to eq('TestApp')
        expect(saved_config['app']['version']).to eq('1.0.0')
        
        loaded_config = helper.load_settings(temp_file_path)
        expect(loaded_config['app']['name']).to eq('TestApp')
        expect(loaded_config['app']['version']).to eq('1.0.0')
        
        app_name = helper.get_param_config(temp_file_path, 'app', 'name')
        app_version = helper.get_param_config(temp_file_path, 'app', 'version')
        expect(app_name).to eq('TestApp')
        expect(app_version).to eq('1.0.0')
      end
    end
  end
end
