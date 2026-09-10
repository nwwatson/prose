module Api
  module TokenAuthenticatable
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_api_token!
    end

    private

    def authenticate_api_token!
      token_string = extract_bearer_token
      return render_unauthorized("Missing or invalid Authorization header") unless token_string

      api_token = ApiToken.find_by_raw_token(token_string)
      return render_unauthorized("Invalid API token") unless api_token

      api_token.touch_usage!(ip_address: request.remote_ip)
      Current.user = api_token.user
    end

    def extract_bearer_token
      header = request.headers["Authorization"]
      return nil unless header&.start_with?("Bearer ")

      header.delete_prefix("Bearer ")
    end

    def render_unauthorized(message)
      render json: { error: message }, status: :unauthorized
    end
  end
end
