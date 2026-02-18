module Trackable
  extend ActiveSupport::Concern

  private

  def track_post_view(post)
    TrackPostViewJob.perform_later(
      post_id: post.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      referrer: request.referrer
    )
  end
end
