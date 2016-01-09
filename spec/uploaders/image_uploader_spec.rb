require 'rails_helper'

RSpec.describe ImageUploader do
  let(:uploader) { ImageUploader.new }
  let(:model) { double('Model', id: 123, class: double('ModelClass', to_s: 'TestModel')) }
  let(:mounted_as) { :image }

  before do
    uploader.instance_variable_set(:@model, model)
    uploader.instance_variable_set(:@mounted_as, mounted_as)
  end

  describe 'storage configuration' do
    context 'storage type' do
      it 'uses file storage' do
        expect(uploader._storage).to eq(CarrierWave::Storage::File)
      end
    end
  end

  describe '#store_dir' do
    context 'when model and mounted_as are set' do
      it 'generates correct store directory path' do
        expected_path = "uploads/test_model/image/123"
        expect(uploader.store_dir).to eq(expected_path)
      end
    end

    context 'with different model class' do
      let(:model) { double('Model', id: 456, class: double('ModelClass', to_s: 'AnotherModel')) }
      
      it 'generates path with correct model class' do
        expected_path = "uploads/another_model/image/456"
        expect(uploader.store_dir).to eq(expected_path)
      end
    end

    context 'with different mounted_as' do
      let(:mounted_as) { :photo }
      
      it 'generates path with correct mounted_as' do
        expected_path = "uploads/test_model/photo/123"
        expect(uploader.store_dir).to eq(expected_path)
      end
    end
  end

  describe 'image processing' do
    context 'thumb200 version' do
      let(:thumb200_version) { uploader.versions[:thumb200] }
      
      it 'creates thumb200 version with correct dimensions' do
        expect(thumb200_version).not_to be_nil
        
        expect(thumb200_version.processors).to include([:resize_to_fit, [300, 300], nil])
        expect(thumb200_version.processors).to include([:resize_to_fill, [180, 180], nil])
        expect(thumb200_version.processors).to include([:convert, 'jpg', nil])
      end

      context 'full_filename method' do
        it 'returns correct filename for special case' do
          special_file = double('File', size: 29)
          allow(special_file).to receive(:index).with('img').and_return(0)
          
          filename = thumb200_version.full_filename(special_file)
          expect(filename).to eq('thumb200_img.jpg')
        end

        it 'returns version_name + filename for other cases' do
          normal_file = double('File', size: 30)
          allow(normal_file).to receive(:index).with('img').and_return(nil)
          allow(normal_file).to receive(:to_s).and_return('30')
          
          filename = thumb200_version.full_filename(normal_file)
          expect(filename).to eq('thumb200_30')
        end
      end
    end
  end

  describe '#extension_white_list' do
    context 'allowed extensions' do
      it 'allows jpg, jpeg, and png files' do
        allowed_extensions = %w(jpg jpeg png)
        expect(uploader.extension_white_list).to match_array(allowed_extensions)
      end
    end

    context 'extension format' do
      it 'returns an array' do
        expect(uploader.extension_white_list).to be_an(Array)
      end
    end
  end

  describe '#filename' do
    context 'when original_filename is present' do
      before do
        allow(uploader).to receive(:original_filename).and_return('test.jpg')
        allow(uploader).to receive(:file).and_return(double('File', extension: 'jpg'))
      end

      it 'generates filename with secure token and original extension' do
        filename = uploader.filename
        expect(filename).to end_with('.jpg')
        expect(filename).to match(/^img\d{12}[a-f0-9]+\.jpg$/)
      end
    end

    context 'when original_filename is nil' do
      before do
        allow(uploader).to receive(:original_filename).and_return(nil)
      end

      it 'returns nil' do
        expect(uploader.filename).to be_nil
      end
    end

    context 'when original_filename is empty string' do
      before do
        allow(uploader).to receive(:original_filename).and_return('')
      end

      it 'returns nil' do
        expect(uploader.filename).to be_nil
      end
    end

    context 'when file extension is different' do
      before do
        allow(uploader).to receive(:original_filename).and_return('test.png')
        allow(uploader).to receive(:file).and_return(double('File', extension: 'png'))
      end

      it 'uses the file extension' do
        filename = uploader.filename
        expect(filename).to end_with('.png')
        expect(filename).to match(/^img\d{12}[a-f0-9]+\.png$/)
      end
    end
  end

  describe '#secure_token' do
    context 'token generation' do
      it 'generates token with specified length' do
        token = uploader.send(:secure_token, 10)
        expect(token).to match(/^img\d{12}[a-f0-9]+$/)
        expect(token.length).to be >= 17 
      end
    end

    context 'token caching' do
      it 'caches token in model instance variable' do
        first_token = uploader.send(:secure_token, 16)
        second_token = uploader.send(:secure_token, 16)
        
        expect(first_token).to eq(second_token)
      end
    end

    context 'different mounted_as' do
      let(:mounted_as) { :photo }
      
      it 'uses correct instance variable name' do
        token = uploader.send(:secure_token, 16)
        expect(token).to start_with('img')
      end
    end

    context 'token format' do
      it 'includes timestamp and random hex' do
        token = uploader.send(:secure_token, 16)
        
        expect(token).to match(/^img\d{12}[a-f0-9]+$/)
        expect(token.length).to be >= 20 
      end
    end
  end

  describe 'included modules' do
    context 'DebHelper' do
      it 'includes DebHelper module' do
        expect(ImageUploader.included_modules).to include(DebHelper)
      end
    end

    context 'UploadHelper' do
      it 'includes UploadHelper module' do
        expect(ImageUploader.included_modules).to include(UploadHelper)
      end
    end

    context 'CarrierWave::MiniMagick' do
      it 'includes CarrierWave::MiniMagick module' do
        expect(ImageUploader.included_modules).to include(CarrierWave::MiniMagick)
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from CarrierWave::Uploader::Base' do
      expect(ImageUploader.superclass).to eq(CarrierWave::Uploader::Base)
    end
  end

  describe 'version processing' do
    context 'thumb200 version processing order' do
      it 'applies processors in correct order' do
        thumb200_version = uploader.versions[:thumb200]
        processors = thumb200_version.processors

        resize_fit_index = processors.index { |p| p[0] == :resize_to_fit }
        resize_fill_index = processors.index { |p| p[0] == :resize_to_fill }
        convert_index = processors.index { |p| p[0] == :convert }
        
        expect(resize_fit_index).to be < resize_fill_index
        expect(convert_index).to be > resize_fill_index
      end
    end
  end
end
