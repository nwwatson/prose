module Post::Versionable
  extend ActiveSupport::Concern
  include Prunable

  VERSION_COOLDOWN = 5.minutes

  included do
    has_many :post_versions, dependent: :delete_all
  end

  def create_version!(user:)
    version = post_versions.create!(
      user: user,
      version_number: PostVersion.next_version_number_for(self),
      title: title,
      subtitle: subtitle,
      content_html: content&.body&.to_html,
      body_plain: body_plain
    )
    prune_old_versions!
    version
  end

  def create_version_if_needed!(user:)
    return unless version_cooldown_elapsed?

    create_version!(user: user)
  end

  def version_cooldown_elapsed?
    last_created_at = post_versions.maximum(:created_at)
    last_created_at.nil? || last_created_at < VERSION_COOLDOWN.ago
  end

  def restore_version!(version)
    update!(
      title: version.title,
      subtitle: version.subtitle,
      content: version.content_html
    )
  end

  private

  def prune_old_versions!
    prune_to_newest(post_versions.ordered, keep: PostVersion::MAX_VERSIONS_PER_POST)
  end
end
