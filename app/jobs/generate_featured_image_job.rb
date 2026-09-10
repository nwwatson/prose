class GenerateFeaturedImageJob < ApplicationJob
  queue_as :default

  def perform(post_id, prompt, user_id)
    post = Post.find(post_id)
    settings = SiteSetting.current

    image = ::Ai::Client.paint(prompt, settings)

    post.featured_image.attach(
      io: StringIO.new(image.to_blob),
      filename: "ai-featured-#{post.id}-#{Time.current.to_i}.png",
      content_type: image.mime_type || "image/png"
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "post_#{post.id}_ai_image",
      target: "ai-image-modal-content",
      partial: "admin/ai/featured_image_preview",
      locals: { post: post.reload }
    )
  rescue RubyLLM::Error => e
    Turbo::StreamsChannel.broadcast_replace_to(
      "post_#{post_id}_ai_image",
      target: "ai-image-modal-content",
      partial: "admin/ai/featured_image_error",
      locals: { error: e.message, post: Post.find_by(id: post_id) }
    )
  end
end
