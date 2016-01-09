class Style < ActiveRecord::Base
  has_many :queue_images, dependent: :destroy
  has_many :clients, through: :queue_images
  has_many :contents, through: :queue_images
  mount_uploader :image, ImageUploader
  
  validates :image, presence: true
end
