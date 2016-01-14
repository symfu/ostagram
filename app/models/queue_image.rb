class QueueImage < ActiveRecord::Base
  STATUS_DELETED = -100
  STATUS_ERROR = -1
  STATUS_HIDDEN = 0
  STATUS_NOT_PROCESSED = 1
  STATUS_IN_PROCESS = 2
  STATUS_PROCESSED = 11
  STATUS_PROCESSED_BY_BOT = 101

  SECONDS_PER_MINUTE = 60
  MINUTES_PER_HOUR = 60
  HOURS_PER_DAY = 24
  DAYS_PER_MONTH = 30
  MONTHS_PER_YEAR = 12

  MINIMUM_PROGRESS = 0.0

  has_many :pimages, dependent: :destroy
  belongs_to :client
  belongs_to :content
  belongs_to :style
  has_many :likes, foreign_key: "queue_id", dependent: :destroy

  scope :last_n_days, ->(days) { where('ftime > ?', days.days.ago) }
  scope :processed, -> { where(status: STATUS_PROCESSED) }
  scope :processing, -> { where(status: STATUS_IN_PROCESS) }
  scope :pending, -> { where(status: STATUS_NOT_PROCESSED) }
  scope :visible, -> { where.not(status: [STATUS_DELETED, STATUS_HIDDEN]) }
  
  validates :progress, numericality: { greater_than_or_equal_to: MINIMUM_PROGRESS }
  
  after_commit :update_likes_count, on: [:create, :update, :destroy]

  def get_queue_item_status
    case status
    when STATUS_DELETED then "Deleted"
    when STATUS_ERROR then "Error during processing"
    when STATUS_HIDDEN then "Hidden"
    when STATUS_NOT_PROCESSED then "Waiting for processing"
    when STATUS_IN_PROCESS then "Processing"
    when STATUS_PROCESSED then processed_status_message
    when STATUS_PROCESSED_BY_BOT then bot_processed_status_message
    else "Undefined"
    end
  end

  def status_description
    get_queue_item_status
  end

  def time_ago
    return '' if updated_at.nil?
    
    time_difference_in_minutes = calculate_time_difference_in_minutes
    return 'now' if time_difference_in_minutes < 1

    format_time_difference(time_difference_in_minutes)
  end

  def result_image
    return nil if pimages.empty?
    
    pimages.order(created_at: :desc).first
  end

  def most_recent_result_image
    result_image
  end
  
  def update_likes_count!
    update_column(:likes_count, likes.count)
  end

  def deleted?
    status == STATUS_DELETED
  end

  def processing?
    status == STATUS_IN_PROCESS
  end

  def processed?
    [STATUS_PROCESSED, STATUS_PROCESSED_BY_BOT].include?(status)
  end

  def pending?
    status == STATUS_NOT_PROCESSED
  end

  def has_error?
    status == STATUS_ERROR
  end

  def visible?
    ![STATUS_DELETED, STATUS_HIDDEN].include?(status)
  end
  
  private
  
  def processed_status_message
    return "Processed" unless ptime.present?
    
    "Processed in #{formatted_processing_time}"
  end

  def bot_processed_status_message
    return "Processed by bot" unless ptime.present?
    
    "Processed by bot in #{formatted_processing_time}"
  end

  def formatted_processing_time
    ptime.strftime("%H:%M:%S")
  end

  def calculate_time_difference_in_minutes
    (Time.current - updated_at) / SECONDS_PER_MINUTE
  end

  def format_time_difference(minutes_ago)
    return format_minutes(minutes_ago) if minutes_ago < MINUTES_PER_HOUR
    
    hours_ago = minutes_ago / MINUTES_PER_HOUR
    return format_hours(hours_ago) if hours_ago < HOURS_PER_DAY
    
    days_ago = hours_ago / HOURS_PER_DAY
    return format_days(days_ago) if days_ago < DAYS_PER_MONTH
    
    months_ago = days_ago / DAYS_PER_MONTH
    return format_months(months_ago) if months_ago < MONTHS_PER_YEAR
    
    years_ago = months_ago / MONTHS_PER_YEAR
    format_years(years_ago)
  end

  def format_minutes(minutes)
    "#{minutes.to_i} min"
  end

  def format_hours(hours)
    "#{hours.to_i} h"
  end

  def format_days(days)
    "#{days.to_i} d"
  end

  def format_months(months)
    "#{months.to_i} m"
  end

  def format_years(years)
    "#{years.to_i} y"
  end

  def update_likes_count
    update_likes_count!
  end
end
