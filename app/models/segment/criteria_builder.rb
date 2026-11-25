module Segment::CriteriaBuilder
  extend ActiveSupport::Concern

  CRITERIA_ATTRIBUTES = %i[label_ids label_mode subscribed_after subscribed_before engagement].freeze

  included do
    attribute :label_ids
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

  # Only the attributes assigned since the last save replace their stored
  # criterion (a blank value removes it), so saves that don't come from the form
  # leave filter_criteria alone.
  def build_filter_criteria
    assigned = CRITERIA_ATTRIBUTES.select { |name| public_send("#{name}_came_from_user?") }
    return if assigned.empty?

    criteria = stored_criteria
    assign_label_criteria(criteria) if assigned.intersect?(%i[label_ids label_mode])

    (assigned - %i[label_ids label_mode]).each do |name|
      criteria[name] = read_attribute(name).presence
    end

    self.filter_criteria = criteria.compact
  end

  def assign_label_criteria(criteria)
    stored = criteria.delete(:labels) || {}
    ids = label_ids_came_from_user? ? read_attribute(:label_ids) : stored[:ids]
    ids = Array(ids).reject(&:blank?).map(&:to_i)
    mode = label_mode_came_from_user? ? read_attribute(:label_mode) : stored[:mode]

    criteria[:labels] = { ids: ids, mode: mode.presence || "any_of" } if ids.present?
  end
end
