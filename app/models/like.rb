class Like < ActiveRecord::Base
  belongs_to :queue_image, foreign_key: 'queue_id'
  belongs_to :client
  
  validates :client_id, presence: true
  validates :queue_id, presence: true
  
  after_create :update_queue_image_likes_count
  after_destroy :update_queue_image_likes_count
  
  private
  
  def update_queue_image_likes_count
    queue_image.update_likes_count! if queue_image
  end
end
