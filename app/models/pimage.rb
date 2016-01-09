class Pimage < ActiveRecord::Base
  mount_uploader :imageurl, PimageUploader
  belongs_to :queue_image
  
  validates :queue_image_id, presence: true
end
