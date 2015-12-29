class BotResqueJob
  @queue = :job1

  def initialize

  end

  def self.perform(*arg)
    bot_job = BotJob.new
    bot_job.execute
  end

end