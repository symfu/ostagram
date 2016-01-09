require 'rails_helper'

RSpec.describe QueueImage, type: :model do
  describe 'associations' do
    it { should belong_to(:client) }
    it { should belong_to(:content) }
    it { should belong_to(:style) }
    it { should have_many(:pimages).dependent(:destroy) }
    it { should have_many(:likes).with_foreign_key('queue_id') }
  end

  describe 'scopes' do
    describe '.last_n_days' do
      let!(:recent_queue_image) { create(:queue_image, :recent) }
      let!(:old_queue_image) { create(:queue_image, :old) }

      it 'returns queue images from last n days' do
        expect(QueueImage.last_n_days(3)).to include(recent_queue_image)
        expect(QueueImage.last_n_days(3)).not_to include(old_queue_image)
      end

      it 'returns empty when no images in time range' do
        expect(QueueImage.last_n_days(1)).to be_empty
      end
    end
  end

  describe '#time_ago' do
    let(:queue_image) { build(:queue_image) }

    context 'when updated_at is nil' do
      it 'returns empty string' do
        queue_image.updated_at = nil
        expect(queue_image.time_ago).to eq('')
      end
    end

    context 'when updated_at is present' do
      it 'returns "now" for less than 1 minute' do
        queue_image.updated_at = 30.seconds.ago
        expect(queue_image.time_ago).to eq('now')
      end

      it 'returns minutes for less than 1 hour' do
        queue_image.updated_at = 30.minutes.ago
        expect(queue_image.time_ago).to eq('30 min')
      end

      it 'returns hours for less than 1 day' do
        queue_image.updated_at = 5.hours.ago
        expect(queue_image.time_ago).to eq('5 h')
      end

      it 'returns days for less than 1 month' do
        queue_image.updated_at = 15.days.ago
        expect(queue_image.time_ago).to eq('15 d')
      end

      it 'returns months for less than 1 year' do
        queue_image.updated_at = 6.months.ago
        expect(queue_image.time_ago).to eq('6 m')
      end

      it 'returns years for more than 1 year' do
        queue_image.updated_at = 2.years.ago
        expect(queue_image.time_ago).to eq('2 y')
      end
    end
  end

  describe '#result_image' do
    let(:queue_image) { create(:queue_image) }

    context 'when no pimages exist' do
      it 'returns nil' do
        expect(queue_image.result_image).to be_nil
      end
    end

    context 'when pimages exist' do
      let!(:old_pimage) { create(:pimage, queue_image: queue_image, created_at: 1.hour.ago) }
      let!(:new_pimage) { create(:pimage, queue_image: queue_image, created_at: Time.current) }

      it 'returns the most recent pimage' do
        expect(queue_image.result_image).to eq(new_pimage)
      end
    end

    context 'when multiple pimages exist with same timestamp' do
      let!(:pimage1) { create(:pimage, queue_image: queue_image, created_at: Time.current) }
      let!(:pimage2) { create(:pimage, queue_image: queue_image, created_at: Time.current) }

      it 'returns one of the pimages with latest timestamp' do
        expect([pimage1, pimage2]).to include(queue_image.result_image)
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:queue_image)).to be_valid
    end

    it 'has a valid in_process factory' do
      expect(build(:queue_image, :in_process)).to be_valid
    end

    it 'has a valid processed factory' do
      expect(build(:queue_image, :processed)).to be_valid
    end

    it 'has a valid processed_by_bot factory' do
      expect(build(:queue_image, :processed_by_bot)).to be_valid
    end

    it 'has a valid error factory' do
      expect(build(:queue_image, :error)).to be_valid
    end

    it 'has a valid deleted factory' do
      expect(build(:queue_image, :deleted)).to be_valid
    end

    it 'has a valid hidden factory' do
      expect(build(:queue_image, :hidden)).to be_valid
    end
  end

  describe 'associations with traits' do
    it 'creates pimages when using with_pimages trait' do
      queue_image = create(:queue_image, :with_pimages)
      expect(queue_image.pimages.count).to eq(3)
    end

    it 'creates likes when using with_likes trait' do
      queue_image = create(:queue_image, :with_likes)
      expect(queue_image.likes.count).to eq(5)
      expect(queue_image.likes_count).to eq(5)
    end
  end

  describe 'status transitions' do
    let(:queue_image) { create(:queue_image) }

    it 'can transition from not_processed to in_process' do
      expect(queue_image.status).to eq(1) # STATUS_NOT_PROCESSED
      queue_image.update!(status: 2, progress: 25.0) # STATUS_IN_PROCESS
      expect(queue_image.status).to eq(2)
      expect(queue_image.progress).to eq(25.0)
    end

    it 'can transition to processed' do
      queue_image.update!(
        status: 11, # STATUS_PROCESSED
        progress: 100.0,
        ftime: Time.current,
        ptime: Time.current - 5.minutes
      )
      expect(queue_image.status).to eq(11)
      expect(queue_image.progress).to eq(100.0)
      expect(queue_image.ftime).to be_present
      expect(queue_image.ptime).to be_present
    end

    it 'can transition to error' do
      queue_image.update!(status: -1, progress: 0.0) # STATUS_ERROR
      expect(queue_image.status).to eq(-1)
      expect(queue_image.progress).to eq(0.0)
    end
  end

  describe 'database constraints' do
    it 'enforces client_id presence' do
      expect {
        create(:queue_image, client: nil)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'enforces style_id presence' do
      expect {
        create(:queue_image, style: nil)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'enforces content_id presence' do
      expect {
        create(:queue_image, content: nil)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe 'default values' do
    let(:queue_image) { create(:queue_image) }

    it 'sets default status to 1' do
      expect(queue_image.status).to eq(1)
    end

    it 'sets default init_str to empty string' do
      expect(queue_image.init_str).to eq('')
    end

    it 'sets default result to empty string' do
      expect(queue_image.result).to eq('')
    end

    it 'sets default end_status to 11' do
      expect(queue_image.end_status).to eq(11)
    end

    it 'sets default likes_count to 0' do
      expect(queue_image.likes_count).to eq(0)
    end

    it 'sets default progress to 0.0' do
      expect(queue_image.progress).to eq(0.0)
    end
  end

  describe 'timestamps' do
    let(:queue_image) { create(:queue_image) }

    it 'sets stime to current time by default' do
      expect(queue_image.stime).to be_within(1.second).of(Time.current)
    end

    it 'does not set ptime by default' do
      expect(queue_image.ptime).to be_nil
    end

    it 'does not set ftime by default' do
      expect(queue_image.ftime).to be_nil
    end
  end

  describe 'progress tracking' do
    let(:queue_image) { create(:queue_image) }

    it 'allows progress updates' do
      queue_image.update!(progress: 75.5)
      expect(queue_image.progress).to eq(75.5)
    end

    it 'validates progress range' do
      expect(queue_image.update(progress: -10.0)).to be false
      expect(queue_image.update(progress: 150.0)).to be true 
    end
  end

  describe 'likes association' do
    let(:queue_image) { create(:queue_image) }
    let(:client) { create(:client) }

    it 'can have multiple likes' do
      create_list(:like, 3, queue_image: queue_image, client: client)
      expect(queue_image.likes.count).to eq(3)
    end

    it 'updates likes_count when likes are added' do
      expect(queue_image.likes_count).to eq(0)
      create(:like, queue_image: queue_image, client: client)
      queue_image.update_likes_count!
      queue_image.reload
      expect(queue_image.likes_count).to eq(1)
    end
  end
end
