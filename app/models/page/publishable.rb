module Page::Publishable
  extend ActiveSupport::Concern

  included do
    scope :live, -> { published.where("published_at <= ?", Time.current) }
  end

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def revert_to_draft!
    update!(status: :draft, published_at: nil)
  end
end
