# Shared by the JSON endpoints the bookmark buttons call for signed-in readers.
# Anonymous readers keep their list in localStorage and never hit these.
module ReadingListJson
  extend ActiveSupport::Concern

  included do
    before_action :require_identity_json
  end

  private

  def require_identity_json
    return if identity_signed_in?

    render json: { error: t("flash.identity_authentication.sign_in_required") }, status: :unauthorized
  end

  def render_reading_list(status: :ok)
    render json: { post_ids: current_identity.reading_list_post_ids }, status: status
  end
end
