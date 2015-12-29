module ConstHelper
  STATUS_DELETED = -100
  STATUS_ERROR = -1
  STATUS_HIDDEN = 0
  STATUS_NOT_PROCESSED = 1
  STATUS_IN_PROCESS = 2
  STATUS_PROCESSED = 11
  STATUS_PROCESSED_BY_BOT = 101
  ##
  BOT_STYLE_IMAGE = 101
  GALLERY_STYLE_IMAGE = 201
  #
  BOT_CONTENT_IMAGE = 101
  ##
  CLIENT_TYPE_ADMIN = 300
  CLIENT_TYPE_USER = 0
  ##
  VIEW_STYLE_LOAD_FILE = 0
  VIEW_STYLE_FROM_LIST = 1
  VIEW_STYLE_FROM_LENTA = 2

  def get_queue_item_status(item)
    case item.status
    when STATUS_DELETED then return "Deleted"
    when STATUS_ERROR then return "Error during processing"
    when STATUS_HIDDEN then return "Hidden"
    when STATUS_NOT_PROCESSED then return "Waiting for processing"
    when STATUS_IN_PROCESS then return "Processing"
    when STATUS_PROCESSED then return "Processed in #{item.ptime.strftime("%H:%M:%S") if !item.ptime.nil?}"
    when STATUS_PROCESSED_BY_BOT then return "Processed by bot in #{item.ptime.strftime("%H:%M:%S") if !item.ptime.nil?}"
    end
  end

end