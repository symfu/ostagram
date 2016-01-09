require 'rails_helper'

RSpec.describe Like, type: :model do
  describe 'associations' do
    it { should belong_to(:client) }
    it { should belong_to(:queue_image).with_foreign_key('queue_id') }
  end

  describe 'database schema' do
    it 'has required columns' do
      expect(Like.column_names).to include(
        'id', 'client_id', 'queue_id', 'created_at', 'updated_at'
      )
    end

    it 'has correct column types' do
      expect(Like.columns_hash['client_id'].type).to eq(:integer)
      expect(Like.columns_hash['queue_id'].type).to eq(:integer)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:like)).to be_valid
    end

    it 'has a valid recent factory' do
      expect(build(:like, :recent)).to be_valid
    end

    it 'has a valid old factory' do
      expect(build(:like, :old)).to be_valid
    end
  end

  describe 'client association' do
    let(:client) { create(:client) }
    let(:like) { create(:like, client: client) }

    it 'belongs to a client' do
      expect(like.client).to eq(client)
    end

    it 'can access client attributes' do
      expect(like.client.name).to be_present
      expect(like.client.email).to be_present
    end

    it 'is destroyed when client is destroyed' do
      like_id = like.id
      client.destroy
      expect(Like.find_by(id: like_id)).to be_nil
    end
  end

  describe 'queue_image association' do
    let(:queue_image) { create(:queue_image) }
    let(:like) { create(:like, queue_image: queue_image) }

    it 'belongs to a queue image' do
      expect(like.queue_image).to eq(queue_image)
    end

    it 'can access queue image attributes' do
      expect(like.queue_image.client).to be_present
      expect(like.queue_image.content).to be_present
      expect(like.queue_image.style).to be_present
    end

    it 'is destroyed when queue image is destroyed' do
      like_id = like.id
      queue_image.destroy
      expect(Like.find_by(id: like_id)).to be_nil
    end
  end

  describe 'model validations' do
    it 'enforces client_id presence' do
      expect {
        create(:like, client: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'enforces queue_id presence' do
      expect {
        create(:like, queue_image: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'timestamps' do
    let(:like) { create(:like) }

    it 'sets created_at and updated_at' do
      expect(like.created_at).to be_present
      expect(like.updated_at).to be_present
    end

    it 'updates updated_at when modified' do
      original_updated_at = like.updated_at
      like.touch
      expect(like.updated_at).to be > original_updated_at
    end
  end

  describe 'scopes and queries' do
    let!(:recent_like) { create(:like, :recent) }
    let!(:old_like) { create(:like, :old) }

    it 'can find likes by creation time' do
      recent_likes = Like.where('created_at > ?', 2.hours.ago)
      expect(recent_likes).to include(recent_like)
      expect(recent_likes).not_to include(old_like)
    end

    it 'can find old likes' do
      old_likes = Like.where('created_at < ?', 2.days.ago)
      expect(old_likes).to include(old_like)
      expect(old_likes).not_to include(recent_like)
    end

    it 'can order by creation time' do
      ordered_likes = Like.order(:created_at)
      expect(ordered_likes.first).to eq(old_like)
      expect(ordered_likes.last).to eq(recent_like)
    end
  end

  describe 'through associations' do
    let(:like) { create(:like) }

    it 'can access client through like' do
      expect(like.client).to be_present
      expect(like.client.name).to be_present
    end

    it 'can access queue image through like' do
      expect(like.queue_image).to be_present
      expect(like.queue_image.client).to be_present
    end
  end

  describe 'multiple likes scenarios' do
    let(:client) { create(:client) }
    let(:queue_image) { create(:queue_image) }

    it 'allows multiple likes from same client to different queue images' do
      like1 = create(:like, client: client, queue_image: create(:queue_image))
      like2 = create(:like, client: client, queue_image: create(:queue_image))
      
      expect(client.likes.count).to eq(2)
      expect(like1.queue_image).not_to eq(like2.queue_image)
    end

    it 'allows multiple likes from different clients to same queue image' do
      client1 = create(:client)
      client2 = create(:client)
      
      like1 = create(:like, client: client1, queue_image: queue_image)
      like2 = create(:like, client: client2, queue_image: queue_image)
      
      expect(queue_image.likes.count).to eq(2)
      expect(like1.client).not_to eq(like2.client)
    end
  end

  describe 'factory traits integration' do
    it 'creates likes with different timestamps' do
      recent_like = create(:like, :recent)
      old_like = create(:like, :old)

      expect(recent_like.created_at).to be > 2.hours.ago
      expect(old_like.created_at).to be < 2.days.ago
    end
  end

  describe 'validation scenarios' do
    it 'is valid with all required fields' do
      like = build(:like)
      expect(like).to be_valid
    end

    it 'can have multiple likes for same client' do
      client = create(:client)
      queue_image1 = create(:queue_image)
      queue_image2 = create(:queue_image)
      
      like1 = create(:like, client: client, queue_image: queue_image1)
      like2 = create(:like, client: client, queue_image: queue_image2)
      
      expect(like1).to be_valid
      expect(like2).to be_valid
      expect(client.likes.count).to eq(2)
    end

    it 'can have multiple likes for same queue image' do
      queue_image = create(:queue_image)
      client1 = create(:client)
      client2 = create(:client)
      
      like1 = create(:like, client: client1, queue_image: queue_image)
      like2 = create(:like, client: client2, queue_image: queue_image)
      
      expect(like1).to be_valid
      expect(like2).to be_valid
      expect(queue_image.likes.count).to eq(2)
    end
  end

  describe 'counter cache integration' do
    let(:queue_image) { create(:queue_image) }
    let(:client) { create(:client) }

    it 'updates queue image likes_count when like is created' do
      expect(queue_image.likes_count).to eq(0)
      create(:like, queue_image: queue_image, client: client)
      queue_image.reload
      expect(queue_image.likes_count).to eq(1)
    end

    it 'updates queue image likes_count when like is destroyed' do
      like = create(:like, queue_image: queue_image, client: client)
      queue_image.reload
      expect(queue_image.likes_count).to eq(1)
      
      like.destroy
      queue_image.reload
      expect(queue_image.likes_count).to eq(0)
    end
  end

  describe 'foreign key relationships' do
    it 'uses correct foreign key for queue_image association' do
      like = Like.new
      expect(like.queue_id).to be_nil
      like.queue_image = create(:queue_image)
      expect(like.queue_id).to eq(like.queue_image.id)
    end

    it 'uses correct foreign key for client association' do
      like = Like.new
      expect(like.client_id).to be_nil
      like.client = create(:client)
      expect(like.client_id).to eq(like.client.id)
    end
  end

  describe 'data integrity' do
    let(:like) { create(:like) }

    it 'maintains referential integrity' do
      expect(like.client).to be_present
      expect(like.queue_image).to be_present
    end

    it 'can be reloaded from database' do
      like_id = like.id
      reloaded_like = Like.find(like_id)
      expect(reloaded_like.client).to eq(like.client)
      expect(reloaded_like.queue_image).to eq(like.queue_image)
    end
  end
end
