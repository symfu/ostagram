require 'rails_helper'

RSpec.describe Content, type: :model do
  describe 'associations' do
    it { should have_many(:queue_images).dependent(:destroy) }
    it { should have_many(:clients).through(:queue_images) }
    it { should have_many(:styles).through(:queue_images) }
  end

  describe 'uploaders' do
    it 'mounts image uploader' do
      expect(Content.uploaders[:image]).to eq(ImageUploader)
    end
  end

  describe 'database schema' do
    it 'has required columns' do
      expect(Content.column_names).to include(
        'id', 'image', 'status', 'created_at', 'updated_at'
      )
    end

    it 'has correct column types' do
      expect(Content.columns_hash['image'].type).to eq(:string)
      expect(Content.columns_hash['status'].type).to eq(:integer)
    end
  end

  describe 'default values' do
    let(:content) { create(:content) }

    it 'sets default status to 0' do
      expect(content.status).to eq(Content::STATUS_HIDDEN)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:content)).to be_valid
    end

    it 'has a valid active factory' do
      expect(build(:content, :active)).to be_valid
    end

    it 'has a valid processed factory' do
      expect(build(:content, :processed)).to be_valid
    end

    it 'has a valid error factory' do
      expect(build(:content, :error)).to be_valid
    end

    it 'has a valid deleted factory' do
      expect(build(:content, :deleted)).to be_valid
    end
  end

  describe 'associations with traits' do
    it 'creates queue images when using with_queue_images trait' do
      content = create(:content, :with_queue_images)
      expect(content.queue_images.count).to eq(2)
    end
  end

  describe 'status values' do
    it 'accepts valid status values' do
      expect(build(:content, status: Content::STATUS_HIDDEN)).to be_valid    
      expect(build(:content, status: Content::BOT_CONTENT_IMAGE)).to be_valid
    end
  end

  describe 'image presence' do
    it 'requires image to be present' do
      content = build(:content, image: nil)
      expect(content).not_to be_valid
    end

    it 'accepts valid image file' do
      content = build(:content)
      expect(content).to be_valid
      expect(content.image).to be_present
    end
  end

  describe 'queue images association' do
    let(:content) { create(:content) }
    let(:client) { create(:client) }
    let(:style) { create(:style) }

    it 'can have multiple queue images' do
      create_list(:queue_image, 3, content: content, client: client, style: style)
      expect(content.queue_images.count).to eq(3)
    end

    it 'destroys associated queue images when deleted' do
      queue_image = create(:queue_image, content: content, client: client, style: style)
      expect { content.destroy }.to change { QueueImage.count }.by(-1)
    end
  end

  describe 'through associations' do
    let(:content) { create(:content) }
    let(:client) { create(:client) }
    let(:style) { create(:style) }

    before do
      create(:queue_image, content: content, client: client, style: style)
    end

    it 'can access clients through queue images' do
      expect(content.clients).to include(client)
    end

    it 'can access styles through queue images' do
      expect(content.styles).to include(style)
    end
  end

  describe 'model validations' do
    it 'enforces image presence' do
      expect {
        create(:content, image: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'timestamps' do
    let(:content) { create(:content) }

    it 'sets created_at and updated_at' do
      expect(content.created_at).to be_present
      expect(content.updated_at).to be_present
    end

    it 'updates updated_at when modified' do
      original_updated_at = content.updated_at
      content.update!(status: Content::BOT_CONTENT_IMAGE)
      expect(content.updated_at).to be > original_updated_at
    end
  end

  describe 'image uploader functionality' do
    let(:content) { create(:content) }

    it 'stores image path' do
      expect(content.image).to be_present
      expect(content.image.path).to be_present
    end

    it 'can be updated with new image' do
      new_image = Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'fixtures', 'test_pimage.jpg'), 
        'image/jpeg'
      )
      content.update!(image: new_image)
      expect(content.image).to be_present
    end
  end

end
