module WorkerHelper
  public

  def start_workers
    worker_name = :server1

    begin
      if Resque.size(worker_name) == 0
        Resque.enqueue(ResqueJob, worker_name)
      end
    rescue => e
      Rails.logger.error("Error starting workers: #{e.message}")
    end
  end

  def start_bot
    worker_name = :bot1

    if Resque.size(worker_name) == 0
      Resque.enqueue(BotResqueJob, worker_name)
    end
  end

end