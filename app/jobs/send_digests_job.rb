# Emails every confirmed subscriber on the given digest frequency ("weekly" or
# "monthly") a summary of the posts published since their last digest, limited
# to posts sent to the mailing lists they're subscribed to.
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
    # Subscribers who received the same digest and share the same lists share a
    # posts query, so a run usually needs one per list combination rather than
    # one per subscriber.
    post_ids_for = Hash.new { |cache, (since, list_ids)| cache[[ since, list_ids ]] = live_post_ids(since, now, list_ids) }

    Subscriber.confirmed.where(email_frequency: frequency).in_batches do |batch|
      list_ids_by_subscriber = active_list_ids_by_subscriber(batch)

      sent_ids = batch.filter_map do |subscriber|
        list_ids = list_ids_by_subscriber.fetch(subscriber.id, [])
        next if list_ids.empty?

        post_ids = post_ids_for[[ subscriber.digest_window_start(now), list_ids ]]
        next if post_ids.empty?

        DigestMailer.digest(subscriber, post_ids.first(POST_LIMIT), post_ids.size).deliver_later
        subscriber.id
      end

      Subscriber.where(id: sent_ids).update_all(last_digest_at: now) if sent_ids.any?
    end
  end

  private

  def active_list_ids_by_subscriber(batch)
    MailingListSubscription
      .where(subscriber_id: batch.select(:id), mailing_list_id: MailingList.active.select(:id))
      .order(:mailing_list_id)
      .pluck(:subscriber_id, :mailing_list_id)
      .each_with_object(Hash.new { |ids, key| ids[key] = [] }) { |(subscriber_id, list_id), ids| ids[subscriber_id] << list_id }
  end

  def live_post_ids(since, now, list_ids)
    Post.live
      .where(published_at: since...now)
      .where(id: MailingListPost.where(mailing_list_id: list_ids).select(:post_id))
      .by_publication_date
      .pluck(:id)
  end
end
