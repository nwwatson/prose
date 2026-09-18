module Subscriber::EmailPreferences
  extend ActiveSupport::Concern

  # How often a subscriber hears about new posts. `none` only stops post
  # emails (per-post notifications and digests); newsletters still arrive until
  # the subscriber unsubscribes.
  DIGEST_PERIODS = { "weekly" => 1.week, "monthly" => 1.month }.freeze
  PREFERENCES_TOKEN_EXPIRY = 30.days

  included do
    enum :email_frequency, { immediate: 0, weekly: 1, monthly: 2, none: 3 }, prefix: :email, validate: true

    before_save :move_digest_cursor, if: :will_save_change_to_email_frequency?
  end

  class_methods do
    def find_by_email_preferences_token(token)
      find_by(id: preferences_verifier.verified(token))
    end

    def preferences_verifier
      Rails.application.message_verifier("email_preferences")
    end
  end

  def email_preferences_token
    self.class.preferences_verifier.generate(id, expires_in: PREFERENCES_TOKEN_EXPIRY)
  end

  def email_digest?
    DIGEST_PERIODS.key?(email_frequency)
  end

  # Start of the publication window the subscriber's next digest covers.
  # `last_digest_at` marks how far posts have already been delivered; with no
  # cursor the digest covers the most recent period.
  def digest_window_start(now = Time.current)
    last_digest_at || now - DIGEST_PERIODS.fetch(email_frequency)
  end

  private

  # Switching from per-post emails to a digest starts the window now, since
  # every earlier post was already emailed; coming back from `none` falls back
  # to the most recent period. Switching between digest frequencies keeps the
  # cursor so no posts fall through the gap.
  def move_digest_cursor
    self.last_digest_at =
      case email_frequency_in_database
      when "immediate" then Time.current
      when "none" then nil
      else last_digest_at
      end
  end
end
