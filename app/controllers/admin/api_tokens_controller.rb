module Admin
  class ApiTokensController < BaseController
    def index
      @api_tokens = if current_user.admin?
        ApiToken.includes(:user).order(created_at: :desc)
      else
        current_user.api_tokens.order(created_at: :desc)
      end
    end

    def create
      record, raw_token = current_user.generate_api_token!(name: params[:name])
      flash[:raw_token] = raw_token
      redirect_to admin_api_tokens_path, notice: "API token created."
    end

    def destroy
      token = find_token
      token.revoke!
      redirect_to admin_api_tokens_path, notice: "API token revoked."
    end

    private

    def find_token
      if current_user.admin?
        ApiToken.find(params[:id])
      else
        current_user.api_tokens.find(params[:id])
      end
    end
  end
end
