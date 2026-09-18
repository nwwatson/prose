module SiteSetting::ActivityPubConfiguration
  extend ActiveSupport::Concern

  USERNAME_FORMAT = /\A[a-z0-9_]{1,30}\z/

  included do
    encrypts :activitypub_private_key, deterministic: false

    normalizes :activitypub_username, with: ->(username) { username.strip.downcase.delete_prefix("@") }
    validates :activitypub_username, format: { with: USERNAME_FORMAT }

    # The keypair is created the first time federation is switched on and never
    # rotated automatically: remote servers cache the public key by its key id.
    before_save :generate_activitypub_keypair, if: -> { activitypub_enabled? && activitypub_private_key.blank? }
  end

  def activitypub_handle
    "@#{activitypub_username}@#{ActivityPub::Urls.host}"
  end

  def activitypub_signing_key
    @activitypub_signing_key ||= OpenSSL::PKey::RSA.new(activitypub_private_key) if activitypub_private_key.present?
  end

  private

  def generate_activitypub_keypair
    key = OpenSSL::PKey::RSA.generate(2048)
    self.activitypub_private_key = key.private_to_pem
    self.activitypub_public_key = key.public_to_pem
    @activitypub_signing_key = nil
  end
end
