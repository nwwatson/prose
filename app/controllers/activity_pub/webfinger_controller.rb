module ActivityPub
  class WebfingerController < BaseController
    def show
      return head :not_found unless own_resource?(params[:resource].to_s)

      response.headers["Access-Control-Allow-Origin"] = "*"
      render json: {
        subject: "acct:#{SiteSetting.current.activitypub_username}@#{Urls.host}",
        aliases: [ Urls.actor_url, Urls.base_url ],
        links: [
          { rel: "self", type: CONTENT_TYPE, href: Urls.actor_url },
          { rel: "http://webfinger.net/rel/profile-page", type: "text/html", href: Urls.base_url }
        ]
      }, content_type: "application/jrd+json"
    end

    private

    def own_resource?(resource)
      return true if resource == Urls.actor_url

      username, domain = resource.delete_prefix("acct:").delete_prefix("@").split("@", 2)
      username.to_s.downcase == SiteSetting.current.activitypub_username &&
        [ Urls.host, request.host_with_port ].include?(domain.to_s.downcase)
    end
  end
end
