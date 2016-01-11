class QueueImage < ActiveRecord::Base
  # Status constants
  STATUS_DELETED = -100
  STATUS_ERROR = -1
  STATUS_HIDDEN = 0
  STATUS_NOT_PROCESSED = 1
  STATUS_IN_PROCESS = 2
  STATUS_PROCESSED = 11
  STATUS_PROCESSED_BY_BOT = 101

  has_many :pimages, dependent: :destroy
  belongs_to :client
  belongs_to :content
  belongs_to :style
  has_many :likes, foreign_key: "queue_id", dependent: :destroy

  scope :last_n_days, lambda { |d| where('ftime > ?', Time.now - d.days) }
  
  validates :progress, numericality: { greater_than_or_equal_to: 0.0 }
  
  after_commit :update_likes_count, on: [:create, :update, :destroy]
  
  def get_queue_item_status
    case self.status
    when STATUS_DELETED then return "Deleted"
    when STATUS_ERROR then return "Error during processing"
    when STATUS_HIDDEN then return "Hidden"
    when STATUS_NOT_PROCESSED then return "Waiting for processing"
    when STATUS_IN_PROCESS then return "Processing"
    when STATUS_PROCESSED then return "Processed in #{self.ptime.strftime("%H:%M:%S") if self.ptime.present?}"
    when STATUS_PROCESSED_BY_BOT then return "Processed by bot in #{self.ptime.strftime("%H:%M:%S") if self.ptime.present?}"
    else return "Undefined"
    end
  end

  def time_ago
    return '' if updated_at.nil?
    t_ago = (Time.now - updated_at) / 60

    return 'now' if t_ago < 1
    str = "#{t_ago.to_i} min"
    t_ago = (t_ago / 60)
    if t_ago < 1
      return str
    else
      str = "#{t_ago.to_i} h"
    end
    t_ago = (t_ago / 24)
    if t_ago < 1
      return str
    else
      str = "#{t_ago.to_i} d"
    end
    t_ago = (t_ago / 30)
    if t_ago < 1
      return str
    else
      str = "#{t_ago.to_i} m"
    end
    t_ago = (t_ago / 12)
    if t_ago < 1
      return str
    else
      str = "#{t_ago.to_i} y"
    end
    str
  end

  def result_image
    if pimages.count > 0
      pimages.all.order('created_at DESC').first
    end
  end
  
  def update_likes_count!
    update_column(:likes_count, likes.count)
  end
  
  private
  
  def update_likes_count
    update_likes_count!
  end
end
