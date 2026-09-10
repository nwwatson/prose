module Webhooks
  class CommentSerializer
    def self.call(comment)
      {
        id: comment.id,
        post_id: comment.post_id,
        body: comment.body,
        approved: comment.approved,
        author: comment.identity&.name,
        created_at: comment.created_at.iso8601
      }
    end
  end
end
