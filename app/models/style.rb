class Style < ActiveRecord::Base
  STATUS_HIDDEN = 0
  BOT_STYLE_IMAGE = 101
  GALLERY_STYLE_IMAGE = 201
  
  has_many :queue_images, dependent: :destroy
  has_many :clients, through: :queue_images
  has_many :contents, through: :queue_images
  mount_uploader :image, ImageUploader
  
  validates :image, presence: true
end
