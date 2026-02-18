module Admin
  class CommentsController < BaseController
    def index
      @comments = Comment.includes(:post, :identity).order(created_at: :desc)

      case params[:filter]
      when "pending"
        @comments = @comments.pending_moderation
      when "approved"
        @comments = @comments.approved
      end
    end

    def update
      @comment = Comment.find(params[:id])
      @comment.update!(approved: params[:approved])
      redirect_to admin_comments_path, notice: "Comment #{@comment.approved? ? 'approved' : 'rejected'}."
    end

    def destroy
      @comment = Comment.find(params[:id])
      @comment.destroy
      redirect_to admin_comments_path, notice: "Comment deleted."
    end
  end
end
