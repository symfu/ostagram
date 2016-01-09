require 'rails_helper'

RSpec.describe Pimage, type: :model do
  describe 'associations' do
    it { should belong_to(:queue_image) }
  end

  describe 'uploaders' do
    it 'mounts imageurl uploader' do
      expect(Pimage.uploaders[:imageurl]).to eq(PimageUploader)
    end
  end

  describe 'database schema' do
    it 'has required columns' do
      expect(Pimage.column_names).to include(
        'id', 'queue_image_id', 'iterate', 'imageurl', 'created_at', 'updated_at'
      )
    end

    it 'has correct column types' do
      expect(Pimage.columns_hash['queue_image_id'].type).to eq(:integer)
      expect(Pimage.columns_hash['iterate'].type).to eq(:integer)
      expect(Pimage.columns_hash['imageurl'].type).to eq(:string)
    end
  end

  describe 'default values' do
    let(:pimage) { create(:pimage) }

    it 'sets default iterate to 1' do
      expect(pimage.iterate).to eq(1)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:pimage)).to be_valid
    end

    it 'has a valid first_iteration factory' do
      expect(build(:pimage, :first_iteration)).to be_valid
    end

    it 'has a valid second_iteration factory' do
      expect(build(:pimage, :second_iteration)).to be_valid
    end

    it 'has a valid final_iteration factory' do
      expect(build(:pimage, :final_iteration)).to be_valid
    end

    it 'has a valid recent factory' do
      expect(build(:pimage, :recent)).to be_valid
    end

    it 'has a valid old factory' do
      expect(build(:pimage, :old)).to be_valid
    end
  end

  describe 'iterate field' do
    it 'can store various iterate values' do
      iterate_values = [1, 2, 5, 10, 100]
      
      iterate_values.each do |iterate_value|
        pimage = create(:pimage, iterate: iterate_value)
        expect(pimage.iterate).to eq(iterate_value)
      end
    end

    it 'can be incremented' do
      pimage = create(:pimage, iterate: 1)
      pimage.increment!(:iterate)
      expect(pimage.iterate).to eq(2)
    end

    it 'can be decremented' do
      pimage = create(:pimage, iterate: 10)
      pimage.decrement!(:iterate)
      expect(pimage.iterate).to eq(9)
    end

    it 'can be set to high values' do
      pimage = create(:pimage, iterate: 1000)
      expect(pimage.iterate).to eq(1000)
    end
  end

  describe 'imageurl field' do
    it 'can store image path' do
      pimage = create(:pimage)
      expect(pimage.imageurl).to be_present
      expect(pimage.imageurl.path).to be_present
    end

    it 'can be updated with new image' do
      pimage = create(:pimage)
      new_image = Rack::Test::UploadedFile.new(
        Rails.root.join('spec', 'fixtures', 'test_content.jpg'), 
        'image/jpeg'
      )
      pimage.update!(imageurl: new_image)
      expect(pimage.imageurl).to be_present
    end
  end

  describe 'queue_image association' do
    let(:queue_image) { create(:queue_image) }
    let(:pimage) { create(:pimage, queue_image: queue_image) }

    it 'belongs to a queue image' do
      expect(pimage.queue_image).to eq(queue_image)
    end

    it 'can access queue image attributes' do
      expect(pimage.queue_image.client).to be_present
      expect(pimage.queue_image.content).to be_present
      expect(pimage.queue_image.style).to be_present
    end

    it 'is destroyed when queue image is destroyed' do
      pimage_id = pimage.id
      queue_image.destroy
      expect(Pimage.find_by(id: pimage_id)).to be_nil
    end
  end

  describe 'model validations' do
    it 'enforces queue_image_id presence' do
      expect {
        create(:pimage, queue_image: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'timestamps' do
    let(:pimage) { create(:pimage) }

    it 'sets created_at and updated_at' do
      expect(pimage.created_at).to be_present
      expect(pimage.updated_at).to be_present
    end

    it 'updates updated_at when modified' do
      original_updated_at = pimage.updated_at
      pimage.update!(iterate: 5)
      expect(pimage.updated_at).to be > original_updated_at
    end
  end

  describe 'image uploader functionality' do
    let(:pimage) { create(:pimage) }

    it 'stores image path' do
      expect(pimage.imageurl).to be_present
      expect(pimage.imageurl.path).to be_present
    end

    it 'can handle different image formats' do
      expect(pimage.imageurl).to be_present
    end
  end

  describe 'scopes and queries' do
    let!(:first_pimage) { create(:pimage, iterate: 1) }
    let!(:second_pimage) { create(:pimage, iterate: 2) }
    let!(:final_pimage) { create(:pimage, iterate: 10) }
    let!(:recent_pimage) { create(:pimage, :recent) }
    let!(:old_pimage) { create(:pimage, :old) }

    it 'can find pimage by iterate value' do
      expect(Pimage.where(iterate: 1)).to include(first_pimage)
      expect(Pimage.where(iterate: 2)).to include(second_pimage)
      expect(Pimage.where(iterate: 10)).to include(final_pimage)
    end

    it 'can find pimages by iterate range' do
      early_iterations = Pimage.where('iterate <= ?', 2)
      expect(early_iterations).to include(first_pimage, second_pimage)
      expect(early_iterations).not_to include(final_pimage)
    end

    it 'can order by iterate' do
      ordered_pimages = Pimage.order(:iterate)
      expect(ordered_pimages.first).to eq(first_pimage)
      expect(ordered_pimages.last).to eq(final_pimage)
    end

    it 'can find recent pimages' do
      recent_pimages = Pimage.where('created_at > ?', 2.hours.ago)
      expect(recent_pimages).to include(first_pimage, second_pimage, final_pimage)
      expect(recent_pimages).not_to include(old_pimage)
    end

    it 'can find old pimages' do
      old_pimages = Pimage.where('created_at < ?', 2.days.ago)
      expect(old_pimages).to include(old_pimage)
      expect(old_pimages).not_to include(first_pimage, second_pimage, final_pimage, recent_pimage)
    end
  end

  describe 'iteration tracking' do
    let(:queue_image) { create(:queue_image) }

    it 'tracks iteration progress' do
      pimage1 = create(:pimage, queue_image: queue_image, iterate: 1)
      pimage2 = create(:pimage, queue_image: queue_image, iterate: 2)
      pimage3 = create(:pimage, queue_image: queue_image, iterate: 3)

      expect(queue_image.pimages.count).to eq(3)
      expect(queue_image.pimages.order(:iterate).pluck(:iterate)).to eq([1, 2, 3])
    end

    it 'can have multiple iterations for same queue image' do
      create_list(:pimage, 5, queue_image: queue_image)
      expect(queue_image.pimages.count).to eq(5)
    end
  end

  describe 'through associations from queue_image' do
    let(:queue_image) { create(:queue_image) }
    let(:pimage) { create(:pimage, queue_image: queue_image) }

    it 'can access client through queue image' do
      expect(pimage.queue_image.client).to be_present
    end

    it 'can access content through queue image' do
      expect(pimage.queue_image.content).to be_present
    end

    it 'can access style through queue image' do
      expect(pimage.queue_image.style).to be_present
    end
  end

  describe 'validation scenarios' do
    it 'is valid with all required fields' do
      pimage = build(:pimage)
      expect(pimage).to be_valid
    end

    it 'is valid with high iterate values' do
      pimage = build(:pimage, iterate: 9999)
      expect(pimage).to be_valid
    end

    it 'is valid with zero iterate value' do
      pimage = build(:pimage, iterate: 0)
      expect(pimage).to be_valid
    end

    it 'is valid with negative iterate value' do
      pimage = build(:pimage, iterate: -1)
      expect(pimage).to be_valid
    end
  end

  describe 'factory traits integration' do
    let(:queue_image) { create(:queue_image) }

    it 'creates pimages with different iterate values' do
      pimage1 = create(:pimage, :first_iteration, queue_image: queue_image)
      pimage2 = create(:pimage, :second_iteration, queue_image: queue_image)
      pimage3 = create(:pimage, :final_iteration, queue_image: queue_image)

      expect(pimage1.iterate).to eq(1)
      expect(pimage2.iterate).to eq(2)
      expect(pimage3.iterate).to eq(10)
    end

    it 'creates pimages with different timestamps' do
      recent_pimage = create(:pimage, :recent, queue_image: queue_image)
      old_pimage = create(:pimage, :old, queue_image: queue_image)

      expect(recent_pimage.created_at).to be > 2.hours.ago
      expect(old_pimage.created_at).to be < 2.days.ago
    end
  end
end
