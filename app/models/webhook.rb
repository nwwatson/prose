class Webhook < ApplicationRecord
  EVENTS = %w[
    post.published post.updated post.deleted post.scheduled post.unpublished
    subscriber.created subscriber.deleted
    comment.created comment.approved
  ].freeze

  MAX_CONSECUTIVE_FAILURES = 5

  has_many :webhook_deliveries, dependent: :destroy

  encrypts :signing_secret, deterministic: false

  before_validation :generate_signing_secret, on: :create

  validates :url, presence: true
  validates :events, presence: true
  validate :url_is_http_or_https
  validate :events_are_known

  scope :active, -> { where(active: true) }

  def subscribed_to?(event)
    events.include?(event)
  end

  def record_delivery_result!(success:, response_code: nil)
    attrs = { last_triggered_at: Time.current, last_response_code: response_code }

    if success
      attrs[:consecutive_failures] = 0
    else
      attrs[:consecutive_failures] = consecutive_failures + 1
      attrs[:active] = false if attrs[:consecutive_failures] >= MAX_CONSECUTIVE_FAILURES
    end

    update!(attrs)
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
    errors.add(:url, "must be a valid http:// or https:// URL") unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:url, "must be a valid http:// or https:// URL")
  end
end
