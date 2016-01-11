require 'rails_helper'

RSpec.describe Style, type: :model do
  describe 'associations' do
    it { should have_many(:queue_images).dependent(:destroy) }
    it { should have_many(:clients).through(:queue_images) }
    it { should have_many(:contents).through(:queue_images) }
  end

  describe 'uploaders' do
    it 'mounts image uploader' do
      expect(Style.uploaders[:image]).to eq(ImageUploader)
    end
  end

  describe 'database schema' do
    it 'has required columns' do
      expect(Style.column_names).to include(
                                      'id', 'image', 'init', 'status', 'use_counter', 'created_at', 'updated_at'
                                    )
    end

    it 'has correct column types' do
      expect(Style.columns_hash['image'].type).to eq(:string)
      expect(Style.columns_hash['init'].type).to eq(:string)
      expect(Style.columns_hash['status'].type).to eq(:integer)
      expect(Style.columns_hash['use_counter'].type).to eq(:integer)
    end
  end

  describe 'default values' do
    let(:style) { create(:style) }

    it 'sets default status to 0' do
      expect(style.status).to eq(Style::STATUS_HIDDEN)
    end

    it 'sets default use_counter to 0' do
      expect(style.use_counter).to eq(0)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:style)).to be_valid
    end

    it 'has a valid active factory' do
      expect(build(:style, :active)).to be_valid
    end

    it 'has a valid processed factory' do
      expect(build(:style, :processed)).to be_valid
    end

    it 'has a valid popular factory' do
      expect(build(:style, :popular)).to be_valid
    end
  end

  describe 'associations with traits' do
    it 'creates queue images when using with_queue_images trait' do
      style = create(:style, :with_queue_images)
      expect(style.queue_images.count).to eq(3)
    end
  end

  describe 'status values' do
    it 'accepts valid status values' do
      expect(build(:style, status: Style::BOT_STYLE_IMAGE)).to be_valid
      expect(build(:style, status: Style::GALLERY_STYLE_IMAGE)).to be_valid
    end
  end

  describe 'image presence' do
    it 'requires image to be present' do
      style = build(:style, image: nil)
      expect(style).not_to be_valid
    end

    it 'accepts valid image file' do
      style = build(:style)
      expect(style).to be_valid
      expect(style.image).to be_present
    end
  end

  describe 'init field' do
    it 'can store init value' do
      style = create(:style, init: 'mona_lisa')
      expect(style.init).to eq('mona_lisa')
    end

    it 'can have nil init value' do
      style = build(:style, init: nil)
      expect(style).to be_valid
    end
  end

  describe 'use_counter' do
    let(:style) { create(:style) }

    it 'starts at 0' do
      expect(style.use_counter).to eq(0)
    end

    it 'can be incremented' do
      style.increment!(:use_counter)
      expect(style.use_counter).to eq(1)
    end

    it 'can be set to high values' do
      style.update!(use_counter: 1000)
      expect(style.use_counter).to eq(1000)
    end

    it 'can be decremented' do
      style.update!(use_counter: 10)
      style.decrement!(:use_counter)
      expect(style.use_counter).to eq(9)
    end
  end

  describe 'queue images association' do
    let(:style) { create(:style) }
    let(:client) { create(:client) }
    let(:content) { create(:content) }

    it 'can have multiple queue images' do
      create_list(:queue_image, 3, style: style, client: client, content: content)
      expect(style.queue_images.count).to eq(3)
    end

    it 'destroys associated queue images when deleted' do
      queue_image = create(:queue_image, style: style, client: client, content: content)
      expect { style.destroy }.to change { QueueImage.count }.by(-1)
    end
  end

  describe 'through associations' do
    let(:style) { create(:style) }
    let(:client) { create(:client) }
    let(:content) { create(:content) }

    before do
      create(:queue_image, style: style, client: client, content: content)
    end

    it 'can access clients through queue images' do
      expect(style.clients).to include(client)
    end

    it 'can access contents through queue images' do
      expect(style.contents).to include(content)
    end
  end

  describe 'model validations' do
    it 'enforces image presence' do
      expect {
        create(:style, image: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'timestamps' do
    let(:style) { create(:style) }

    it 'sets created_at and updated_at' do
      expect(style.created_at).to be_present
      expect(style.updated_at).to be_present
    end

    it 'updates updated_at when modified' do
      original_updated_at = style.updated_at
      style.update!(status: Style::BOT_STYLE_IMAGE)
      expect(style.updated_at).to be > original_updated_at
    end
  end

  describe 'image uploader functionality' do
    let(:style) { create(:style) }

    it 'stores image path' do
      expect(style.image).to be_present
      expect(style.image.path).to be_present
    end

    it 'can be updated with new image' do
      new_image = Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'fixtures', 'test_content.jpg'),
        'image/jpeg'
      )
      style.update!(image: new_image)
      expect(style.image).to be_present
    end
  end

  describe 'scopes and queries' do

    describe 'init field usage' do
      it 'can store various init values' do
        init_values = ['starry_night', 'mona_lisa', 'wave', 'scream', nil]

        init_values.each do |init_value|
          style = create(:style, init: init_value)
          expect(style.init).to eq(init_value)
        end
      end

      it 'can be searched by init value' do
        create(:style, init: 'starry_night')
        create(:style, init: 'mona_lisa')

        starry_styles = Style.where(init: 'starry_night')
        expect(starry_styles.count).to eq(1)
        expect(starry_styles.first.init).to eq('starry_night')
      end
    end
  end
end
