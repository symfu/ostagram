class Style < ActiveRecord::Base
  STATUS_HIDDEN = 0
  BOT_STYLE_IMAGE = 101
  GALLERY_STYLE_IMAGE = 201
  
  has_many :queue_images, dependent: :destroy
  has_many :clients, through: :queue_images
  has_many :contents, through: :queue_images
  
  mount_uploader :image, ImageUploader
  
  validates :image, presence: true

  scope :visible, -> { where.not(status: STATUS_HIDDEN) }
  scope :popular, -> { order(popularity: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  def hidden?
    status == STATUS_HIDDEN
  end


  def visible?
    !hidden?
  end

  def usage_count
    queue_images.count
  end

  def recent_usage_count(days = 30)
    queue_images.where('created_at > ?', days.days.ago).count
  end

  def increment_popularity!
    increment!(:popularity)
  end
end
