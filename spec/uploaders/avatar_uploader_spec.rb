require 'rails_helper'

RSpec.describe AvatarUploader do
  let(:uploader) { AvatarUploader.new }
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

  describe 'image processing versions' do
    context 'to_proc version' do
      let(:to_proc_version) { uploader.versions[:to_proc] }
      
      it 'creates to_proc version with correct dimensions' do
        expect(to_proc_version).not_to be_nil
        
        expect(to_proc_version.processors).to include([:resize_to_fit, [1500, 1500], nil])
        expect(to_proc_version.processors).to include([:resize_to_fill, [1000, 1000], nil])
      end
    end

    context 'thumb200 version' do
      let(:thumb200_version) { uploader.versions[:thumb200] }
      
      it 'creates thumb200 version with correct dimensions' do
        expect(thumb200_version).not_to be_nil
        
        expect(thumb200_version.processors).to include([:resize_to_fit, [300, 300], nil])
        expect(thumb200_version.processors).to include([:resize_to_fill, [180, 180], nil])
      end
    end

    context 'thumb400 version' do
      let(:thumb400_version) { uploader.versions[:thumb400] }
      
      it 'creates thumb400 version with correct dimensions' do
        expect(thumb400_version).not_to be_nil
        
        expect(thumb400_version.processors).to include([:resize_to_fit, [600, 600], nil])
        expect(thumb400_version.processors).to include([:resize_to_fill, [400, 400], nil])
      end
    end

    context 'avatar50 version' do
      let(:avatar50_version) { uploader.versions[:avatar50] }
      
      it 'creates avatar50 version with correct dimensions' do
        expect(avatar50_version).not_to be_nil
        
        expect(avatar50_version.processors).to include([:resize_to_fit, [80, 80], nil])
        expect(avatar50_version.processors).to include([:resize_to_fill, [46, 46], nil])
        expect(avatar50_version.processors).to include([:round, [2], nil])
      end
    end

    context 'avatar100 version' do
      let(:avatar100_version) { uploader.versions[:avatar100] }
      
      it 'creates avatar100 version with correct dimensions' do
        expect(avatar100_version).not_to be_nil
        
        expect(avatar100_version.processors).to include([:resize_to_fit, [150, 150], nil])
        expect(avatar100_version.processors).to include([:resize_to_fill, [100, 100], nil])
        expect(avatar100_version.processors).to include([:round, [2], nil])
      end
    end
  end

  describe 'conditional processing methods' do
    context '#is_processed_image?' do
      it 'returns true for pimage model' do
        pimage_model = double('Model', class: double('ModelClass', to_s: 'Pimage'))
        uploader.instance_variable_set(:@model, pimage_model)
        
        expect(uploader.is_processed_image?(nil)).to be true
      end

      it 'returns false for non-pimage model' do
        other_model = double('Model', class: double('ModelClass', to_s: 'OtherModel'))
        uploader.instance_variable_set(:@model, other_model)
        
        expect(uploader.is_processed_image?(nil)).to be false
      end
    end

    context '#is_content_style_image?' do
      it 'returns true for content model' do
        content_model = double('Model', class: double('ModelClass', to_s: 'Content'))
        uploader.instance_variable_set(:@model, content_model)
        
        expect(uploader.is_content_style_image?(nil)).to be true
      end

      it 'returns true for style model' do
        style_model = double('Model', class: double('ModelClass', to_s: 'Style'))
        uploader.instance_variable_set(:@model, style_model)
        
        expect(uploader.is_content_style_image?(nil)).to be true
      end

      it 'returns false for other models' do
        other_model = double('Model', class: double('ModelClass', to_s: 'OtherModel'))
        uploader.instance_variable_set(:@model, other_model)
        
        expect(uploader.is_content_style_image?(nil)).to be false
      end
    end

    context '#is_user_avatar?' do
      it 'returns true for client model' do
        client_model = double('Model', class: double('ModelClass', to_s: 'Client'))
        uploader.instance_variable_set(:@model, client_model)
        
        expect(uploader.is_user_avatar?(nil)).to be true
      end

      it 'returns false for other models' do
        other_model = double('Model', class: double('ModelClass', to_s: 'OtherModel'))
        uploader.instance_variable_set(:@model, other_model)
        
        expect(uploader.is_user_avatar?(nil)).to be false
      end
    end

    context '#is_content_image?' do
      it 'returns true for content model' do
        content_model = double('Model', class: double('ModelClass', to_s: 'Content'))
        uploader.instance_variable_set(:@model, content_model)
        
        expect(uploader.is_content_image?(nil)).to be true
      end

      it 'returns false for other models' do
        other_model = double('Model', class: double('ModelClass', to_s: 'OtherModel'))
        uploader.instance_variable_set(:@model, other_model)
        
        expect(uploader.is_content_image?(nil)).to be false
      end
    end

    context '#is_style_image?' do
      it 'returns true for style model' do
        style_model = double('Model', class: double('ModelClass', to_s: 'Style'))
        uploader.instance_variable_set(:@model, style_model)
        
        expect(uploader.is_style_image?(nil)).to be true
      end

      it 'returns false for other models' do
        other_model = double('Model', class: double('ModelClass', to_s: 'OtherModel'))
        uploader.instance_variable_set(:@model, other_model)
        
        expect(uploader.is_style_image?(nil)).to be false
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
      end

      it 'generates filename with img prefix and original extension' do
        filename = uploader.filename
        expect(filename).to eq('img.jpg')
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

      it 'returns img with empty extension' do
        filename = uploader.filename
        expect(filename).to eq('img.')
      end
    end

    context 'with different file extensions' do
      it 'handles jpg extension' do
        allow(uploader).to receive(:original_filename).and_return('test.jpg')
        expect(uploader.filename).to eq('img.jpg')
      end

      it 'handles png extension' do
        allow(uploader).to receive(:original_filename).and_return('test.png')
        expect(uploader.filename).to eq('img.png')
      end

      it 'handles jpeg extension' do
        allow(uploader).to receive(:original_filename).and_return('test.jpeg')
        expect(uploader.filename).to eq('img.jpeg')
      end
    end
  end

  describe 'image manipulation methods' do
    context '#rounded_corners' do
      it 'defines the method' do
        expect(uploader).to respond_to(:rounded_corners)
      end
    end

    context '#round' do
      it 'defines the method' do
        expect(uploader).to respond_to(:round)
      end
    end

    context '#round_corner' do
      it 'defines the method' do
        expect(uploader).to respond_to(:round_corner)
      end
    end

    context '#draw_border' do
      it 'defines the method' do
        expect(uploader).to respond_to(:draw_border)
      end
    end
  end

  describe '#move_to_cach' do
    context 'cache behavior' do
      it 'returns false' do
        expect(uploader.move_to_cach).to be false
      end
    end
  end

  describe 'included modules' do
    context 'DebHelper' do
      it 'includes DebHelper module' do
        expect(AvatarUploader.included_modules).to include(DebHelper)
      end
    end

    context 'CarrierWave::MiniMagick' do
      it 'includes CarrierWave::MiniMagick module' do
        expect(AvatarUploader.included_modules).to include(CarrierWave::MiniMagick)
      end
    end
  end

  describe 'inheritance' do
    it 'inherits from CarrierWave::Uploader::Base' do
      expect(AvatarUploader.superclass).to eq(CarrierWave::Uploader::Base)
    end
  end

  describe 'version processing order' do
    context 'processor application order' do
      it 'applies processors in correct order for avatar100' do
        avatar100_version = uploader.versions[:avatar100]
        processors = avatar100_version.processors
        
        resize_fit_index = processors.index { |p| p[0] == :resize_to_fit }
        resize_fill_index = processors.index { |p| p[0] == :resize_to_fill }
        round_index = processors.index { |p| p[0] == :round }
        
        expect(resize_fit_index).to be < resize_fill_index
        expect(round_index).to be > resize_fill_index
      end
    end
  end
end
