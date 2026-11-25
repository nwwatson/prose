class ApplicationJob < ActiveJob::Base
  # Active Job restores the locale a job was enqueued under, which is English for
  # recurring tasks and API requests. The site setting wins, as it does for
  # site requests. `retry_on`/`discard_on` blocks run outside this.
  around_perform do |_job, block|
    I18n.with_locale(SiteSetting.current.locale, &block)
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
