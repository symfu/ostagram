class ResqueJob
  @queue = :server1

  def initialize
  end

  def self.perform(*arg)
    img_job = ImageJob.new(@queue)
    img_job.execute
  end

end