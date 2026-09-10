module Segment::CriteriaBuilder
  extend ActiveSupport::Concern

  included do
    attribute :label_ids, default: []
    attribute :label_mode
    attribute :subscribed_after
    attribute :subscribed_before
    attribute :engagement

    before_validation :build_filter_criteria
  end

  def label_ids
    ids = super.presence || stored_criteria.dig(:labels, :ids)
    Array(ids).reject(&:blank?).map(&:to_i)
  end

  def label_mode
    super.presence || stored_criteria.dig(:labels, :mode) || "any_of"
  end

  def subscribed_after
    super.presence || stored_criteria[:subscribed_after]
  end

  def subscribed_before
    super.presence || stored_criteria[:subscribed_before]
  end

  def engagement
    super.presence || stored_criteria[:engagement]
  end

  private

  def stored_criteria
    filter_criteria&.deep_symbolize_keys || {}
  end

  def build_filter_criteria
    criteria = {}

    ids = Array(read_attribute(:label_ids)).reject(&:blank?).map(&:to_i)
    criteria[:labels] = { ids: ids, mode: read_attribute(:label_mode).presence || "any_of" } if ids.present?

    criteria[:subscribed_after] = read_attribute(:subscribed_after) if read_attribute(:subscribed_after).present?
    criteria[:subscribed_before] = read_attribute(:subscribed_before) if read_attribute(:subscribed_before).present?
    criteria[:engagement] = read_attribute(:engagement) if read_attribute(:engagement).present?

    self.filter_criteria = criteria
  end
end
