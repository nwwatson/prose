module Admin
  module AnalyticsRangeable
    extend ActiveSupport::Concern

    private

    def analytics_range(default:, allowed:)
      @analytics_range ||= AnalyticsRange.parse(params[:range], default: default, allowed: allowed)
    end
  end
end
