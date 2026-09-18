module ActivityPub
  class BaseController < ActionController::API
    CONTENT_TYPE = "application/activity+json".freeze

    before_action :require_federation

    private

    # Federation is opt-in; while it's off, every ActivityPub endpoint 404s.
    def require_federation
      head :not_found unless SiteSetting.current.activitypub_enabled?
    end

    def render_activity(document)
      response.headers["Cache-Control"] = "max-age=60, public"
      render json: document, content_type: CONTENT_TYPE
    end
  end
end
