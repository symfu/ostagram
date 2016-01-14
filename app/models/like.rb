class Like < ActiveRecord::Base
  belongs_to :queue_image, foreign_key: 'queue_id'
  belongs_to :client
  
  validates :client_id, presence: true
  validates :queue_id, presence: true
  
  after_create :increment_queue_image_likes_count
  after_destroy :decrement_queue_image_likes_count
  
  scope :recent, -> { order(created_at: :desc) }
  scope :for_client, ->(client_id) { where(client_id: client_id) }

  def queue_image_exists?
    queue_image.present?
  end

  private
  
  def increment_queue_image_likes_count
    update_queue_image_likes_count if queue_image_exists?
  end

  def decrement_queue_image_likes_count
    update_queue_image_likes_count if queue_image_exists?
  end

  def update_queue_image_likes_count
    queue_image.update_likes_count!
  end
end
