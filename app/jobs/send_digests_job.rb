# Emails every confirmed subscriber on the given digest frequency ("weekly" or
# "monthly") a summary of the posts published since their last digest.
# Scheduled in config/recurring.yml.
#
# Each subscriber's `last_digest_at` is advanced to this run's timestamp once
# their digest is enqueued, so a retried or duplicated run finds an empty window
# instead of re-sending. Subscribers with no new posts are skipped and keep
# their cursor, so the next run still covers everything since their last digest.
class SendDigestsJob < ApplicationJob
  queue_as :default

  POST_LIMIT = 20

  def perform(frequency)
    raise ArgumentError, "Unknown digest frequency: #{frequency}" unless Subscriber::EmailPreferences::DIGEST_PERIODS.key?(frequency)

    now = Time.current
    # Subscribers who received the same digest share a window start, so this
    # usually runs one posts query per run rather than one per subscriber.
    post_ids_since = Hash.new { |cache, since| cache[since] = live_post_ids(since, now) }

    Subscriber.confirmed.where(email_frequency: frequency).in_batches do |batch|
      sent_ids = batch.filter_map do |subscriber|
        post_ids = post_ids_since[subscriber.digest_window_start(now)]
        next if post_ids.empty?

        DigestMailer.digest(subscriber, post_ids.first(POST_LIMIT), post_ids.size).deliver_later
        subscriber.id
      end

      Subscriber.where(id: sent_ids).update_all(last_digest_at: now) if sent_ids.any?
    end
  end

  private

  def live_post_ids(since, now)
    Post.live.where(published_at: since...now).by_publication_date.pluck(:id)
  end
end
