class QueueImage < ActiveRecord::Base
  has_many :pimages, dependent: :destroy
  belongs_to :client
  belongs_to :content
  belongs_to :style
  has_many :likes, foreign_key: "queue_id", dependent: :destroy

  scope :last_n_days, lambda { |d| where('ftime > ?', Time.now - d.days) }
  
  validates :progress, numericality: { greater_than_or_equal_to: 0.0 }
  
  after_commit :update_likes_count, on: [:create, :update, :destroy]
  
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
