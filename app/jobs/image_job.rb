require 'net/ssh'
require 'net/scp'

# @example Basic usage
#   job = ImageJob.new(:server1)
#   job.execute
#
# @example Debug mode
#   job = ImageJob.new(:server1)  
#   job.execute_debug
class ImageJob
  include DebHelper
  include ConstHelper

  # Configuration constants
  DEFAULT_HOSTNAME = "localhost".freeze
  DEFAULT_USERNAME = "root".freeze
  DEFAULT_PASSWORD = "123".freeze
  DEFAULT_REMOTE_NEURAL_PATH = "~/neural-style".freeze
  DEFAULT_ITERATION_COUNT = 10
  DEFAULT_LOCAL_TMP_PATH = '~/tmp/output'.freeze
  DEFAULT_WORKER_NAME = :server1
  DEFAULT_SQUARE_FORMAT = false

  # File name constants
  CONTENT_IMAGE_FILENAME = "content.jpg".freeze
  STYLE_IMAGE_FILENAME = "style.jpg".freeze
  OUTPUT_LOG_FILENAME = "output.log".freeze
  ERROR_LOG_FILENAME = "error.log".freeze
  NEURAL_SCRIPT_FILENAME = "neural.sh".freeze
  
  # Processing constants
  ITERATIONS_MULTIPLIER = 100
  PROCESSING_SLEEP_INTERVAL = 5
  NEURAL_CHECK_SLEEP_INTERVAL = 2
  POST_PROCESS_SLEEP_INTERVAL = 10
  PERCENTAGE_MULTIPLIER = 100

  # Command patterns
  LUA_PROCESS_PATTERN = "th neural_style.lua".freeze
  LUAJIT_PATTERN = "luajit".freeze
  ITERATION_PATTERN = "Iteration %d00".freeze
  
  # Output file patterns
  OUTPUT_FILE_PATTERN = "out_%d00.png".freeze
  FINAL_OUTPUT_FILENAME = "out.png".freeze

  # @return [String] hostname of the remote neural style server
  attr_reader :hostname
  
  # @return [String] username for remote server connection
  attr_reader :username
  
  # @return [String] password for remote server connection (write-only for security)
  attr_writer :password
  
  # @return [String] path to neural-style directory on remote server
  attr_reader :remote_neural_path
  
  # @return [Integer] number of iterations for neural style processing
  attr_reader :iteration_count
  
  # @return [String] local temporary directory path
  attr_reader :local_tmp_path
  
  # @return [Symbol] worker name identifier
  attr_reader :worker_name
  
  # @return [Boolean] whether to use square format for images
  attr_reader :square_format

  # Initialize a new ImageJob
  #
  # @param worker_name [Symbol] the name of the worker server to use
  def initialize(worker_name)
    initialize_default_configuration
    @worker_name = worker_name
  end

  # Set configuration parameters from config file
  #
  # @param worker_name [Symbol] the worker name to load configuration for
  # @return [void]
  def set_config(worker_name)
    return if worker_name.nil?

    config = load_worker_configuration(worker_name)
    return if config.blank?

    apply_configuration(config)
    setup_local_directory
    configure_neural_parameters(config)
    log_configuration(config)
  end

  # Execute the main processing loop
  #
  # This method runs continuously, processing images from the queue until
  # no more images are available for processing.
  #
  # @return [String] "Zero" when no more images to process
  def execute
    log_execution_start
    
    loop do
      queue_item = get_next_queue_item
      
      if queue_item.present?
        process_queue_item(queue_item)
      else
        log_execution_stop
        return "Zero"
      end
      
      sleep PROCESSING_SLEEP_INTERVAL
    end
  end

  # Execute in debug mode for testing
  #
  # @return [String] "Zero" when no more images to process
  def execute_debug
    loop do
      queue_item = get_next_queue_item
      
      if queue_item.present?
        process_debug_item(queue_item)
      else
        log_execution_stop
        return "Zero"
      end
    end
  end

  # Initialize default configuration values
  #
  # @return [void]
  def initialize_default_configuration
    @hostname = DEFAULT_HOSTNAME
    @username = DEFAULT_USERNAME
    @password = DEFAULT_PASSWORD
    @remote_neural_path = DEFAULT_REMOTE_NEURAL_PATH
    @iteration_count = DEFAULT_ITERATION_COUNT
    @local_tmp_path = DEFAULT_LOCAL_TMP_PATH
    @worker_name = DEFAULT_WORKER_NAME
    @square_format = DEFAULT_SQUARE_FORMAT
  end

  # Load worker configuration from config file
  #
  # @param worker_name [Symbol] worker identifier
  # @return [Hash, nil] configuration hash or nil if not found
  def load_worker_configuration(worker_name)
    config_file = Rails.root.join('config/config.secret')
    get_param_config(config_file, :workservers, worker_name.to_sym)
  end

  # Apply loaded configuration to instance variables
  #
  # @param config [Hash] configuration parameters
  # @return [void]
  def apply_configuration(config)
    @hostname = config["host"]
    @username = config["username"]
    @password = config["password"]
    @remote_neural_path = config["remote_neural_path"]
    @iteration_count = config["iteration_count"]
    @admin_email = config["admin_email"]
    @square_format = config["square_format"]
  end

  # Setup local temporary directory
  #
  # @return [void]
  def setup_local_directory
    @local_tmp_path = Rails.root.join("tmp/#{@worker_name}")
    Dir.mkdir(@local_tmp_path) unless Dir.exist?(@local_tmp_path)
  end

  # Configure neural processing parameters
  #
  # @param config [Hash] configuration parameters
  # @return [void]
  def configure_neural_parameters(config)
    @init_params = build_init_params(config)
    @content_image_name = CONTENT_IMAGE_FILENAME
    @style_image_name = STYLE_IMAGE_FILENAME
  end

  # Build initialization parameters string
  #
  # @param config [Hash] configuration parameters
  # @return [String] formatted initialization parameters
  def build_init_params(config)
    base_params = config["init_params"]
    iteration_param = " -num_iterations #{@iteration_count * ITERATIONS_MULTIPLIER}"
    base_params + iteration_param
  end

  # Log configuration (with password masked)
  #
  # @param config [Hash] configuration to log
  # @return [void]
  def log_configuration(config)
    safe_config = config.dup
    safe_config["password"] = "*"
    log "config: #{safe_config}"
  end

  # Log execution start
  #
  # @return [void]
  def log_execution_start
    log "-----------------------Start Demon: #{@worker_name}---------------------"
  end

  # Log execution stop
  #
  # @return [void]
  def log_execution_stop
    log "-----------------------Stop Demon---------------------------"
  end

  # Get the next item from the processing queue
  #
  # @return [QueueImage, nil] next queue item or nil if none available
  def get_next_queue_item
    get_images_from_queue
  end

  # Process a queue item
  #
  # @param queue_item [QueueImage] item to process
  # @return [void]
  def process_queue_item(queue_item)
    log("Images: #{queue_item.attributes}")
    set_config(@worker_name)
    execute_image_processing(queue_item)
  end

  # Process item in debug mode
  #
  # @param queue_item [QueueImage] item to process
  # @return [void]
  def process_debug_item(queue_item)
    set_config(@worker_name)
    
    process_start_time = Time.now
    download_and_save_result(@iteration_count, queue_item)
    process_duration = Time.at(Time.now - process_start_time)
    
    update_queue_item_completion(queue_item, process_duration)
  end

  # Update queue item with completion status
  #
  # @param queue_item [QueueImage] item to update
  # @param process_duration [Time] processing duration
  # @return [void]
  def update_queue_item_completion(queue_item, process_duration)
    queue_item.update({
      status: QueueImage::STATUS_PROCESSED,
      ftime: Time.now,
      ptime: process_duration
    })
  end

  # Check if luajit process exists on remote server
  #
  # @return [String, nil] error message or nil if process is running
  def check_luajit_process_status
    begin
      Net::SSH.start(@hostname, @username, password: @password) do |ssh|
        output = ssh.exec!("ps axu | grep #{LUAJIT_PATTERN}")
        return nil if output.include?(LUA_PROCESS_PATTERN)
        output
      end
    rescue StandardError
      "Command ps axu error"
    end
  end

  # Main image processing workflow
  #
  # @param queue_item [QueueImage] item to process
  # @return [String, nil] error message or nil on success
  def execute_image_processing(queue_item)
    return nil if queue_item.nil?
    
    process_start_time = Time.now
    log_processing_start(queue_item)
    
    # Validate and prepare processing parameters
    return handle_init_string_error(queue_item) unless validate_init_string(queue_item)
    
    # Update queue item status and style usage
    update_processing_status(queue_item, process_start_time)
    
    # Verify server connectivity and setup
    return handle_server_error("get_server_name: false") if get_server_name.nil?
    return handle_server_error("rm_file_on_server: false") unless clear_remote_directory
    
    # Upload images and start processing
    return handle_upload_error unless upload_images_to_server(queue_item)
    
    initiate_neural_processing
    
    # Wait for completion and handle results
    errors = wait_for_processing_completion(queue_item)
    
    finalize_processing(queue_item, process_start_time, errors)
  end

  # Log the start of image processing
  #
  # @param queue_item [QueueImage] item being processed
  # @return [void]
  def log_processing_start(queue_item)
    log "-----------------------"
    log "execute_image item.id = #{queue_item.id}"
  end

  # Validate initialization string for queue item
  #
  # @param queue_item [QueueImage] item to validate
  # @return [Boolean] true if valid, false otherwise
  def validate_init_string(queue_item)
    set_init_str(queue_item)
  end

  # Handle initialization string error
  #
  # @param queue_item [QueueImage] item with error
  # @return [String] error message
  def handle_init_string_error(queue_item)
    error_message = "Init string ERROR"
    queue_item.update(status: QueueImage::STATUS_ERROR, result: error_message)
    log error_message
    error_message
  end

  # Update queue item with processing status
  #
  # @param queue_item [QueueImage] item to update
  # @param start_time [Time] processing start time
  # @return [void]
  def update_processing_status(queue_item, start_time)
    queue_item.update({
      status: QueueImage::STATUS_IN_PROCESS,
      stime: start_time,
      init_str: @init_params
    })
    queue_item.style.update(use_counter: queue_item.style.use_counter + 1)
    log "item.update"
  end

  # Handle server connection errors
  #
  # @param error_message [String] error description
  # @return [String] error message
  def handle_server_error(error_message)
    log error_message
    error_message
  end

  # Handle image upload errors
  #
  # @return [String] error message
  def handle_upload_error
    error_message = "upload_image: false"
    log error_message
    error_message
  end

  # Upload images to remote server
  #
  # @param queue_item [QueueImage] item containing images to upload
  # @return [Boolean] true if successful, false otherwise
  def upload_images_to_server(queue_item)
    prepare_image_filenames(queue_item)
    
    content_upload_success = upload_content_image(queue_item)
    style_upload_success = upload_style_image(queue_item)
    
    if content_upload_success && style_upload_success
      log "upload_content_style_image"
      true
    else
      false
    end
  end

  # Prepare image filenames based on original file extensions
  #
  # @param queue_item [QueueImage] item containing images
  # @return [void]
  def prepare_image_filenames(queue_item)
    content_extension = extract_file_extension(queue_item.content.image.to_s)
    style_extension = extract_file_extension(queue_item.style.image.to_s)
    
    @content_image_name = "content.#{content_extension}"
    @style_image_name = "style.#{style_extension}"
  end

  # Extract file extension from filename
  #
  # @param filename [String] full filename
  # @return [String] file extension
  def extract_file_extension(filename)
    filename.split('.').last
  end

  # Upload content image to server
  #
  # @param queue_item [QueueImage] item containing content image
  # @return [Boolean] upload success status
  def upload_content_image(queue_item)
    if @square_format
      upload_image(queue_item.content.image.to_proc.url, "output/#{@content_image_name}")
    else
      upload_image(queue_item.content.image, "output/#{@content_image_name}")
    end
  end

  # Upload style image to server
  #
  # @param queue_item [QueueImage] item containing style image
  # @return [Boolean] upload success status
  def upload_style_image(queue_item)
    upload_image(queue_item.style.image, "output/#{@style_image_name}")
  end

  # Initiate neural processing on remote server
  #
  # @return [void]
  def initiate_neural_processing
    send_start_process_comm
    log "send_start_process_comm"
    sleep POST_PROCESS_SLEEP_INTERVAL
  end

  # Wait for processing completion and monitor progress
  #
  # @param queue_item [QueueImage] item being processed
  # @return [String, nil] error message or nil on success
  def wait_for_processing_completion(queue_item)
    wait_images(queue_item)
  end

  # Finalize processing and update status
  #
  # @param queue_item [QueueImage] processed item
  # @param start_time [Time] processing start time
  # @param errors [String, nil] any errors encountered
  # @return [String] result status
  def finalize_processing(queue_item, start_time, errors)
    process_duration = calculate_processing_duration(start_time)
    log "process time: #{Time.now - start_time}"
    
    if errors.nil?
      handle_successful_processing(queue_item, process_duration)
    else
      handle_failed_processing(queue_item, process_duration, errors)
    end
    
    update_client_last_process_time(queue_item)
  end

  # Calculate processing duration
  #
  # @param start_time [Time] processing start time
  # @return [Time] duration as Time object
  def calculate_processing_duration(start_time)
    Time.at(Time.now - start_time)
  end

  # Handle successful processing completion
  #
  # @param queue_item [QueueImage] processed item
  # @param duration [Time] processing duration
  # @return [String] success message
  def handle_successful_processing(queue_item, duration)
    queue_item.update({
      status: queue_item.end_status,
      ftime: Time.now,
      ptime: duration
    })
    "OK"
  end

  # Handle failed processing
  #
  # @param queue_item [QueueImage] failed item
  # @param duration [Time] processing duration
  # @param errors [String] error details
  # @return [void]
  def handle_failed_processing(queue_item, duration, errors)
    queue_item.update({
      status: QueueImage::STATUS_ERROR,
      result: errors,
      ftime: Time.now,
      ptime: duration
    })
    
    enhanced_errors = errors + check_neural_start
    send_error_notification(queue_item, enhanced_errors)
    log "wait_images: #{enhanced_errors}"
  end

  # Send error notification email
  #
  # @param queue_item [QueueImage] failed item
  # @param errors [String] error details
  # @return [void]
  def send_error_notification(queue_item, errors)
    ImageMailer.send_error(@admin_email, "", queue_item, errors).deliver_now
  end

  # Update client's last process time
  #
  # @param queue_item [QueueImage] processed item
  # @return [void]
  def update_client_last_process_time(queue_item)
    queue_item.client.update(lastprocess: Time.now)
  end

  # Set initialization string parameters
  #
  # @param item [QueueImage] queue item with style settings
  # @return [Boolean] true if successful, false on error
  def set_init_str(item)
    init = item.style.init
    init = item.init_str unless item.init_str.blank?
    return true if init.blank?
    
    merged_init = merge_init_params(@init_params, init)
    return handle_merge_error(init) if merged_init.nil?
    
    @init_params = merged_init
    log "init: #{merged_init}"
    
    extract_iteration_count(merged_init)
  end

  # Handle initialization parameter merge error
  #
  # @param init [String] original init string
  # @return [Boolean] false
  def handle_merge_error(init)
    log "Merge init error: init_params[#{@init_params}] init[#{init}]"
    false
  end

  # Extract iteration count from init parameters
  #
  # @param init_string [String] initialization parameters
  # @return [Boolean] true if found and valid, false otherwise
  def extract_iteration_count(init_string)
    params_array = init_string.split(' -')
    
    params_array.each do |param|
      next unless param.include?('num_iterations')
      
      param_parts = param.split(' ')
      return false if param_parts.size < 2
      
      @iteration_count = (param_parts[1].to_i / ITERATIONS_MULTIPLIER).to_i
      log "iteration_count: #{@iteration_count}"
      return true
    end
    
    false
  end

  # Merge initialization parameters
  #
  # @param base_init [String] base initialization string
  # @param override_params [String] override parameters
  # @return [String, nil] merged parameters or nil on error
  def merge_init_params(base_init, override_params)
    base_hash = parse_params_to_hash(' ' + base_init)
    override_hash = parse_params_to_hash(' ' + override_params)
    
    return nil if base_hash.nil? || override_hash.nil?
    
    merged_hash = base_hash.merge(override_hash)
    build_params_string(merged_hash)
  end

  # Parse parameter string to hash
  #
  # @param param_string [String] parameter string to parse
  # @return [Hash] parameter hash
  def parse_params_to_hash(param_string)
    result = {}
    param_array = param_string.split(' -')
    
    param_array.each do |param|
      param_parts = param.split(' ')
      case param_parts.count
      when 2
        result[param_parts[0]] = param_parts[1]
      when 1
        result[param_parts[0]] = ''
      end
    end
    
    result
  end

  # Build parameter string from hash
  #
  # @param param_hash [Hash] parameter hash
  # @return [String] formatted parameter string
  def build_params_string(param_hash)
    param_hash.map { |key, value| " -#{key} #{value}" }.join
  end

  # Get images from queue with client prioritization
  #
  # @return [QueueImage, nil] next queue item or nil
  def get_images_from_queue
    # First try clients that haven't been processed
    unprocessed_clients = find_unprocessed_clients
    
    if unprocessed_clients.empty?
      # Then try clients ordered by last process time
      processed_clients = find_processed_clients
      return nil if processed_clients.empty?
      
      client = processed_clients.first
    else
      client = unprocessed_clients.first
    end
    
    log("Client: #{client.attributes}")
    get_next_queue_item_for_client(client)
  end

  # Find clients with unprocessed queue items that haven't been processed before
  #
  # @return [Array<Client>] array of unprocessed clients
  def find_unprocessed_clients
    Client.find_by_sql(
      "SELECT * FROM clients c " \
      "WHERE lastprocess IS NULL " \
      "AND EXISTS (SELECT * FROM queue_images q " \
      "WHERE c.id = q.client_id AND status = #{QueueImage::STATUS_NOT_PROCESSED}) " \
      "ORDER BY created_at ASC"
    )
  end

  # Find clients with unprocessed queue items ordered by last process time
  #
  # @return [Array<Client>] array of clients
  def find_processed_clients
    Client.find_by_sql(
      "SELECT * FROM clients c " \
      "WHERE EXISTS (SELECT * FROM queue_images q " \
      "WHERE c.id = q.client_id AND status = #{QueueImage::STATUS_NOT_PROCESSED}) " \
      "ORDER BY lastprocess ASC"
    )
  end

  # Get next queue item for specific client
  #
  # @param client [Client] client to get queue item for
  # @return [QueueImage, nil] next queue item or nil
  def get_next_queue_item_for_client(client)
    client.queue_images
          .where("status = #{QueueImage::STATUS_NOT_PROCESSED}")
          .order('created_at ASC')
          .first
  end

  # Check neural processing logs and errors
  #
  # @return [String] combined log and error information
  def check_neural_start
    log "check_neural_start"
    
    begin
      error_info = ""
      log_content = download_and_read_output_log
      error_content = download_and_read_error_log
      
      error_info += check_output_log_content(log_content)
      error_info += check_error_log_content(error_content)
      
    rescue StandardError
      error_info += "ERROR during download error.log and output.log\n\n"
    end
    
    format_neural_check_result(error_info, log_content, error_content)
  end

  # Download and read output log from remote server
  #
  # @return [String, nil] log content or nil if not available
  def download_and_read_output_log
    remote_path = "#{@remote_neural_path}/output/#{OUTPUT_LOG_FILENAME}"
    local_path = "#{@local_tmp_path}/#{OUTPUT_LOG_FILENAME}"
    
    Net::SCP.download!(@hostname, @username, remote_path, local_path, password: @password)
    
    if File.exist?(local_path)
      File.read(local_path)
    else
      nil
    end
  end

  # Download and read error log from remote server
  #
  # @return [String, nil] error log content or nil if not available
  def download_and_read_error_log
    remote_path = "#{@remote_neural_path}/output/#{ERROR_LOG_FILENAME}"
    local_path = "#{@local_tmp_path}/#{ERROR_LOG_FILENAME}"
    
    Net::SCP.download!(@hostname, @username, remote_path, local_path, password: @password)
    
    if File.exist?(local_path)
      File.read(local_path)
    else
      nil
    end
  end

  # Check output log content for issues
  #
  # @param log_content [String, nil] log file content
  # @return [String] error message if issues found
  def check_output_log_content(log_content)
    return "NO OUTPUT.LOG!\n\n" if log_content.nil?
    ""
  end

  # Check error log content for issues
  #
  # @param error_content [String, nil] error log content
  # @return [String] error message if issues found
  def check_error_log_content(error_content)
    return "" if error_content.nil?
    error_content.include?("error") ? "ERROR_IN_FILE!\n\n" : ""
  end

  # Format neural check result with log contents
  #
  # @param error_info [String] accumulated error information
  # @param log_content [String, nil] output log content
  # @param error_content [String, nil] error log content
  # @return [String] formatted result
  def format_neural_check_result(error_info, log_content, error_content)
    "#{error_info}output.log:\n\n#{log_content}\n\nerror.log:\n\n#{error_content}\n"
  end

  # Wait for image processing completion
  #
  # @param queue_item [QueueImage] item being processed
  # @return [String, nil] error message or nil on success
  def wait_images(queue_item)
    log "wait_images"
    
    iteration = 1
    
    while iteration <= @iteration_count
      begin
        if iteration_completed?(iteration)
          process_completed_iteration(iteration, queue_item)
          iteration += 1
          next
        end
      rescue StandardError
        # Continue monitoring even if there's an error downloading logs
      end
      
      # Check if neural process is still running
      process_status = check_luajit_process_status
      return process_status unless process_status.nil?
      
      sleep NEURAL_CHECK_SLEEP_INTERVAL
    end
    
    nil
  end

  # Check if specific iteration has completed
  #
  # @param iteration [Integer] iteration number to check
  # @return [Boolean] true if iteration completed
  def iteration_completed?(iteration)
    remote_log_path = "#{@remote_neural_path}/output/#{OUTPUT_LOG_FILENAME}"
    local_log_path = "#{@local_tmp_path}/#{OUTPUT_LOG_FILENAME}"
    
    Net::SCP.download!(@hostname, @username, remote_log_path, local_log_path, password: @password)
    
    return false unless File.exist?(local_log_path)
    
    log_content = File.read(local_log_path)
    target_iteration = format(ITERATION_PATTERN, iteration)
    
    !log_content.nil? && log_content.include?(target_iteration)
  end

  # Process completed iteration
  #
  # @param iteration [Integer] completed iteration number
  # @param queue_item [QueueImage] queue item being processed
  # @return [void]
  def process_completed_iteration(iteration, queue_item)
    sleep NEURAL_CHECK_SLEEP_INTERVAL
    download_and_save_result(iteration, queue_item)
    update_progress_percentage(iteration, queue_item)
  end

  # Update progress percentage for queue item
  #
  # @param iteration [Integer] current iteration
  # @param queue_item [QueueImage] queue item to update
  # @return [void]
  def update_progress_percentage(iteration, queue_item)
    progress_percentage = (iteration.to_f / @iteration_count * PERCENTAGE_MULTIPLIER).round(2)
    queue_item.update(progress: progress_percentage)
  end

  # Download and save processing result
  #
  # @param iteration_number [Integer] iteration number
  # @param queue_item [QueueImage] queue item
  # @return [void]
  def download_and_save_result(iteration_number, queue_item)
    filename, iteration_for_save = determine_output_filename(iteration_number)
    
    download_image(filename)
    local_file_path = "#{@local_tmp_path}/#{filename}"
    save_image(iteration_for_save, queue_item, local_file_path)
    
    send_completion_email(iteration_number, queue_item, local_file_path)
    log "save_image: #{filename}"
  end

  # Determine output filename based on iteration
  #
  # @param iteration_number [Integer] current iteration
  # @return [Array<String, Integer>] filename and iteration number for saving
  def determine_output_filename(iteration_number)
    if iteration_number < @iteration_count
      [format(OUTPUT_FILE_PATTERN, iteration_number), iteration_number]
    else
      [FINAL_OUTPUT_FILENAME, 0]
    end
  end

  # Send completion email if final iteration
  #
  # @param iteration_number [Integer] current iteration
  # @param queue_item [QueueImage] processed item
  # @param local_file_path [String] path to result file
  # @return [void]
  def send_completion_email(iteration_number, queue_item, local_file_path)
    return unless iteration_number == @iteration_count
    
    file_content = File.read(local_file_path)
    ImageMailer.send_image(
      queue_item.client,
      iteration_number,
      @iteration_count,
      file_content
    ).deliver_now
  end

  # Save processed image to database
  #
  # @param iteration_number [Integer] iteration number (0 for final)
  # @param queue_item [QueueImage] associated queue item
  # @param local_file_path [String] path to image file
  # @return [void]
  def save_image(iteration_number, queue_item, local_file_path)
    processed_image = Pimage.new
    processed_image.queue_image_id = queue_item.id
    processed_image.iterate = iteration_number
    
    File.open(local_file_path) do |file|
      processed_image.imageurl = file
    end
    
    processed_image.save!
  end

  # Get server hostname for verification
  #
  # @return [String, nil] server hostname or nil on error
  def get_server_name
    Net::SSH.start(@hostname, @username, password: @password) do |ssh|
      ssh.exec!("hostname")
    end
  rescue StandardError
    nil
  end

  # Clear remote working directory
  #
  # @return [Boolean] true if successful, false otherwise
  def clear_remote_directory
    Net::SSH.start(@hostname, @username, password: @password) do |ssh|
      ssh.exec!("rm -rf #{@remote_neural_path}/output/*")
    end
    true
  rescue StandardError
    false
  end

  # Download image file from remote server
  #
  # @param filename [String] name of file to download
  # @return [Boolean] true if successful, false otherwise
  def download_image(filename)
    remote_path = "#{@remote_neural_path}/#{filename}"
    local_path = "#{@local_tmp_path}/#{filename}"
    
    Net::SCP.download!(@hostname, @username, remote_path, local_path, password: @password)
    true
  rescue StandardError
    false
  end

  # Upload image file to remote server
  #
  # @param local_file_reference [String] local file path or CarrierWave uploader
  # @param remote_filename [String] destination filename on remote server
  # @return [Boolean] true if successful, false otherwise
  def upload_image(local_file_reference, remote_filename)
    remote_path = "#{@remote_neural_path}/#{remote_filename}"
    local_path = Rails.root.join("public#{local_file_reference}")
    
    return false unless File.exist?(local_path)
    
    Net::SCP.upload!(@hostname, @username, local_path.to_s, remote_path, password: @password)
    true
  rescue StandardError
    false
  end

  # Create and upload neural processing script
  #
  # @return [Boolean] true if successful, false otherwise
  def create_and_upload_script
    remote_script_path = "#{@remote_neural_path}/#{NEURAL_SCRIPT_FILENAME}"
    local_script_path = Rails.root.join("config/#{NEURAL_SCRIPT_FILENAME}")
    
    return false unless File.exist?(local_script_path)
    
    begin
      script_content = File.read(local_script_path)
      neural_command = build_neural_command
      log("command: #{neural_command}")
      
      full_script = script_content + neural_command
      Net::SCP.upload!(@hostname, @username, StringIO.new(full_script), remote_script_path, password: @password)
      true
    rescue StandardError
      false
    end
  end

  # Build neural processing command
  #
  # @return [String] complete neural command
  def build_neural_command
    "th neural_style.lua #{@init_params} " \
    "-style_image output/#{@style_image_name} " \
    "-content_image output/#{@content_image_name} " \
    "> output/#{OUTPUT_LOG_FILENAME} 2> output/#{ERROR_LOG_FILENAME} &"
  end

  # Send command to start neural processing
  #
  # @return [Boolean] true if successful, false otherwise
  def send_start_process_comm
    log "send_start_process_comm"
    
    return false unless create_and_upload_script
    
    begin
      Net::SSH.start(@hostname, @username, password: @password) do |ssh|
        execution_command = build_execution_command
        @conn = ssh.exec!(execution_command)
      end
      true
    rescue StandardError
      false
    end
  end

  # Build script execution command
  #
  # @return [String] command to execute neural script
  def build_execution_command
    "cd #{@remote_neural_path} && chmod 777 #{NEURAL_SCRIPT_FILENAME} && ./#{NEURAL_SCRIPT_FILENAME} "
  end

  # Write log message with worker name
  #
  # @param message [String] message to log
  # @return [void]
  def log(message)
    write_log(message, @worker_name)
  end

  # Legacy method - kept for backward compatibility
  # Process image with direct Resque integration (deprecated)
  #
  # @deprecated Use execute_image_processing instead
  def process_image1
    command = build_legacy_command
    Resque.enqueue(WaitJob, @hostname, @username, @password, command)
    sleep(POST_PROCESS_SLEEP_INTERVAL)
    Resque.remove_queue(:server1_wait_answer)
  end

  # Build legacy processing command
  #
  # @return [String] legacy command string
  def build_legacy_command
    "cd #{@remote_neural_path} && export PATH=$PATH:/home/margo/torch/install/bin && export LD_LIBRARY_PATH=/home/margo/torch/install/lib" \
    " && th neural_style.lua -gpu -1 -image_size 500 -num_iterations #{@iteration_count * ITERATIONS_MULTIPLIER}" \
    " -style_image output/#{@style_image_name} -content_image output/#{@content_image_name} -output_image output/out.png" \
    " > output/#{OUTPUT_LOG_FILENAME} 2> output/#{ERROR_LOG_FILENAME} & \n"
  end

  # Legacy method - alternative processing approach (deprecated)
  #
  # @deprecated Use execute_image_processing instead
  # @return [String, Boolean] connection result or false on error
  def process_image3
    begin
      Net::SSH.start(@hostname, @username, password: @password) do |ssh|
        command = build_alternative_command
        @conn = ssh.exec!(command)
      end
      @conn
    rescue StandardError
      false
    end
  end

  # Build alternative processing command
  #
  # @return [String] alternative command string
  def build_alternative_command
    "cd #{@remote_neural_path} && export PATH=$PATH:/home/margo/torch/install/bin" \
    " && export LD_LIBRARY_PATH=/home/margo/torch/install/lib" \
    " && th neural_style.lua #{@init_params}" \
    " -style_image output/#{@style_image_name} -content_image output/#{@content_image_name}" \
    " > output/#{OUTPUT_LOG_FILENAME} 2> output/#{ERROR_LOG_FILENAME} & && exit"
  end

  # Legacy download method (deprecated)
  #
  # @deprecated Use download_image instead
  # @param filename [String] file to download
  # @return [Boolean] success status
  def download_data(filename)
    remote_path = "#{@remote_neural_path}/#{filename}"
    # Note: 'loc' variable is undefined in original - this appears to be a bug
    # Net::SCP.download!(@hostname, @username, remote_path, loc, password: @password)
    true
  rescue StandardError
    false
  end
end