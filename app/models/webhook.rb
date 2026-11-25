class Webhook < ApplicationRecord
  EVENTS = %w[
    post.published post.updated post.deleted post.scheduled post.unpublished
    subscriber.created subscriber.deleted
    comment.created comment.approved
  ].freeze

  MAX_CONSECUTIVE_FAILURES = 5
  DELIVERY_LOG_LIMIT = 100

  has_many :webhook_deliveries, dependent: :destroy

  encrypts :signing_secret, deterministic: false

  before_validation :generate_signing_secret, on: :create

  validates :url, presence: true
  validates :events, presence: true
  validate :url_is_http_or_https
  validate :events_are_known

  scope :active, -> { where(active: true) }
  scope :subscribed_to, ->(event) { where("EXISTS (SELECT 1 FROM json_each(webhooks.events) WHERE json_each.value = ?)", event) }

  def subscribed_to?(event)
    events.include?(event)
  end

  # A failure only counts toward auto-disable when `count_failure` is true —
  # DeliverWebhookJob passes false for attempts that will still be retried, so
  # one event exhausting its retries counts as a single failure. The failure
  # count is incremented in SQL so concurrent deliveries can't lose an update.
  def record_delivery_result!(success:, response_code: nil, count_failure: true)
    now = Time.current
    attrs = { last_triggered_at: now, last_response_code: response_code, updated_at: now }
    attrs[:consecutive_failures] = 0 if success

    transaction do
      self.class.where(id: id).update_all(attrs)
      if !success && count_failure
        self.class.where(id: id).update_all([
          "consecutive_failures = consecutive_failures + 1, " \
          "active = CASE WHEN consecutive_failures + 1 >= ? THEN FALSE ELSE active END",
          MAX_CONSECUTIVE_FAILURES
        ])
      end
    end
    reload
  end

  def prune_deliveries!(keep: DELIVERY_LOG_LIMIT)
    cutoff_ids = webhook_deliveries.recent.offset(keep).pluck(:id)
    webhook_deliveries.where(id: cutoff_ids).delete_all if cutoff_ids.any?
  end

  def regenerate_secret!
    update!(signing_secret: SecureRandom.hex(32))
  end

  private

  def generate_signing_secret
    self.signing_secret ||= SecureRandom.hex(32)
  end

  def events_are_known
    unknown = Array(events) - EVENTS
    errors.add(:events, "contains unknown event types: #{unknown.join(', ')}") if unknown.any?
  end

  def url_is_http_or_https
    return if url.blank?

    uri = URI.parse(url)
    if !uri.is_a?(URI::HTTP) || uri.host.blank?
      errors.add(:url, "must be a valid http:// or https:// URL")
    elsif Webhooks::UrlGuard.blocked_host?(uri.hostname)
      errors.add(:url, "must not point to a local, private, or reserved network address")
    end
  rescue URI::InvalidURIError
    errors.add(:url, "must be a valid http:// or https:// URL")
  end
end
