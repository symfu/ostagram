class Content < ActiveRecord::Base
  STATUS_HIDDEN = 0
  BOT_CONTENT_IMAGE = 101
  
  has_many :queue_images, dependent: :destroy
  has_many :clients, through: :queue_images
  has_many :styles, through: :queue_images
  
  mount_uploader :image, ImageUploader
  
  validates :image, presence: true

  scope :visible, -> { where.not(status: STATUS_HIDDEN) }

  def hidden?
    status == STATUS_HIDDEN
  end

  def visible?
    !hidden?
  end
end
