# frozen_string_literal: true

module Publishable
  extend ActiveSupport::Concern

  included do
    enum :status, { draft: "draft", scheduled: "scheduled", published: "published", archived: "archived" }

    scope :visible, -> { where(status: [ :published ]) }
    scope :scheduled_for_publish, -> { scheduled.where("scheduled_at <= ?", Time.current) }

    before_save :set_published_at
  end

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def unpublish!
    update!(status: :draft, published_at: nil)
  end

  def schedule!(time)
    update!(status: :scheduled, scheduled_at: time)
  end

  def published?
    status == "published"
  end

  def visible?
    published?
  end

  private

  def set_published_at
    if status_changed?(to: "published") && published_at.blank?
      self.published_at = Time.current
    end
  end
end
