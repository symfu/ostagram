require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'validations' do
    subject { build(:client) }
    
    it { should validate_presence_of(:name) }

    it { should validate_uniqueness_of(:name).case_insensitive }
    
    context 'when name is present' do
      it 'validates uniqueness' do
        create(:client, name: 'TestUser')
        client = build(:client, name: 'TestUser')
        expect(client).not_to be_valid
        expect(client.errors[:name]).to include('has already been taken')
      end
    end
    
    context 'when name is blank' do
      it 'does not validate uniqueness' do
        client = build(:client, name: '')
        expect(client).not_to be_valid
        expect(client.errors[:name]).to include("can't be blank")
      end
    end

    it 'validates avatar presence' do
      client = build(:client)
      client.remove_avatar!
      expect(client).not_to be_valid
      expect(client.errors[:avatar]).to include('Please provide an avatar')
    end
  end

  describe 'associations' do
    it { should have_many(:queue_images).dependent(:destroy) }
    it { should have_many(:likes).dependent(:destroy) }
    it { should have_many(:pimages).through(:queue_images) }
  end

  describe 'devise modules' do
    it 'includes default devise modules' do
      expect(Client.devise_modules).to include(
        :database_authenticatable,
        :registerable,
        :recoverable,
        :rememberable,
        :trackable,
        :validatable,
        :lockable
      )
    end
  end

  describe 'uploaders' do
    it 'mounts avatar uploader' do
      expect(Client.uploaders[:avatar]).to eq(AvatarUploader)
    end
  end

  describe 'role methods' do
    let(:user_client) { create(:client, role_id: Client::CLIENT_TYPE_USER) }
    let(:admin_client) { create(:client, role_id: Client::CLIENT_TYPE_ADMIN) }
    let(:nil_role_client) { create(:client, role_id: nil) }

    describe '#user?' do
      it 'returns true for user role' do
        expect(user_client.user?).to be true
      end

      it 'returns true for nil role' do
        expect(nil_role_client.user?).to be true
      end

      it 'returns false for admin role' do
        expect(admin_client.user?).to be false
      end
    end

    describe '#admin?' do
      it 'returns false for user role' do
        expect(user_client.admin?).to be false
      end

      it 'returns false for nil role' do
        expect(nil_role_client.admin?).to be false
      end

      it 'returns true for admin role' do
        expect(admin_client.admin?).to be true
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:client)).to be_valid
    end

    it 'has a valid admin factory' do
      expect(build(:client, :admin)).to be_valid
    end

    it 'has a valid confirmed factory' do
      expect(build(:client, :confirmed)).to be_valid
    end

    it 'has a valid locked factory' do
      expect(build(:client, :locked)).to be_valid
    end
  end

  describe 'associations with traits' do
    it 'creates queue images when using with_queue_images trait' do
      client = create(:client, :with_queue_images)
      expect(client.queue_images.count).to eq(3)
    end

    it 'creates likes when using with_likes trait' do
      client = create(:client, :with_likes)
      expect(client.likes.count).to eq(2)
    end
  end

  describe 'model validations' do
    it 'enforces email uniqueness' do
      create(:client, email: 'test@example.com')
      expect {
        create(:client, email: 'test@example.com')
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'enforces name presence' do
      expect {
        create(:client, name: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'enforces avatar presence' do
      expect {
        create(:client, avatar: nil)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe 'devise functionality' do
    let(:client) { create(:client) }

    it 'can be locked' do
      client.lock_access!
      expect(client.access_locked?).to be true
    end

    it 'can be unlocked' do
      client.lock_access!
      client.unlock_access!
      expect(client.access_locked?).to be false
    end

    it 'tracks sign in count' do
      expect(client.sign_in_count).to eq(0)
      client.increment!(:sign_in_count)
      expect(client.sign_in_count).to eq(1)
    end

    it 'tracks current and last sign in' do
      client.update!(
        current_sign_in_at: Time.current,
        current_sign_in_ip: '127.0.0.1',
        last_sign_in_at: 1.hour.ago,
        last_sign_in_ip: '192.168.1.1'
      )
      expect(client.current_sign_in_at).to be_present
      expect(client.last_sign_in_at).to be_present
    end
  end

  describe 'password validation' do
    it 'requires password confirmation' do
      client = build(:client, password: 'password123', password_confirmation: 'different')
      expect(client).not_to be_valid
      expect(client.errors[:password_confirmation]).to include("doesn't match Password")
    end

    it 'requires minimum password length' do
      client = build(:client, password: '123', password_confirmation: '123')
      expect(client).not_to be_valid
      expect(client.errors[:password]).to include('is too short (minimum is 6 characters)')
    end
  end

  describe 'email validation' do
    it 'validates email format' do
      client = build(:client, email: 'invalid-email')
      expect(client).not_to be_valid
      expect(client.errors[:email]).to include('is invalid')
    end

    it 'accepts valid email format' do
      client = build(:client, email: 'valid@example.com')
      expect(client).to be_valid
    end
  end
end
