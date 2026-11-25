module Admin
  class ApiTokensController < BaseController
    def index
      load_api_tokens
    end

    def create
      record, raw_token = current_user.generate_api_token!(name: params[:name])
      flash[:raw_token] = raw_token
      redirect_to admin_api_tokens_path, notice: t("flash.admin.api_tokens.created")
    rescue ActiveRecord::RecordInvalid => e
      load_api_tokens
      flash.now[:alert] = e.record.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end

    def destroy
      ApiToken.visible_to(current_user).find(params[:id]).revoke!
      redirect_to admin_api_tokens_path, notice: t("flash.admin.api_tokens.revoked")
    end

    private

    def load_api_tokens
      @api_tokens = ApiToken.visible_to(current_user).includes(user: :identity).order(created_at: :desc)
    end
  end
end
