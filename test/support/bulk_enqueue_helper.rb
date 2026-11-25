# Observes ActiveJob.perform_all_later calls. The test adapter records bulk
# enqueued jobs like any other, so this is what tells the two apart.
module BulkEnqueueHelper
  # Returns the jobs of each bulk enqueue made during the block, one array per call.
  def capture_bulk_enqueues(&block)
    batches = []
    subscriber = ->(*, payload) { batches << payload[:jobs] }
    ActiveSupport::Notifications.subscribed(subscriber, "enqueue_all.active_job", &block)
    batches
  end
end
