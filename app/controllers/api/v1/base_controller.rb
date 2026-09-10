module Api
  module V1
    class BaseController < ActionController::API
      include Api::TokenAuthenticatable

      rate_limit to: 60, within: 1.minute

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable

      private

      def render_not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def render_unprocessable(exception)
        render json: { error: exception.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end

      def paginate(scope)
        per_page = [ (params[:per_page] || 20).to_i, 50 ].min
        per_page = 20 if per_page < 1
        page = [ params[:page].to_i, 1 ].max

        total = scope.count
        records = scope.limit(per_page).offset((page - 1) * per_page)

        set_pagination_headers(page: page, per_page: per_page, total: total)
        records
      end

      def set_pagination_headers(page:, per_page:, total:)
        response.set_header("X-Total-Count", total.to_s)

        links = []
        links << %(<#{pagination_url(page + 1, per_page)}>; rel="next") if page * per_page < total
        links << %(<#{pagination_url(page - 1, per_page)}>; rel="prev") if page > 1
        response.set_header("Link", links.join(", ")) if links.any?
      end

      def pagination_url(page, per_page)
        url_for(request.query_parameters.merge(page: page, per_page: per_page, only_path: false, controller: controller_name, action: action_name))
      end
    end
  end
end
