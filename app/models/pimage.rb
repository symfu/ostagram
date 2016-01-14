class Pimage < ActiveRecord::Base
  mount_uploader :imageurl, PimageUploader
  
  belongs_to :queue_image
  
  validates :queue_image_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_queue_image, ->(queue_image_id) { where(queue_image_id: queue_image_id) }
  scope :by_iteration, -> { order(:iterate) }

  def latest_iteration?
    return false unless queue_image && respond_to?(:iterate)
    queue_image.pimages.maximum(:iterate) == iterate
  end

  def processing_complete?
    imageurl.present?
  end

  def iteration_number
    respond_to?(:iterate) ? iterate.to_i : 1
  end
end
