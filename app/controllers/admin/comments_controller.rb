module Admin
  class CommentsController < BaseController
    def index
      comments = Comment.includes(:post, :identity).order(created_at: :desc, id: :desc)
      comments = filter_by_status(comments, { "pending" => :pending_moderation, "approved" => :approved }, value: params[:filter])

      @comments = paginate(comments)
    end

    def update
      @comment = Comment.find(params[:id])

      if ActiveModel::Type::Boolean.new.cast(params[:approved])
        @comment.approve!
      else
        @comment.update!(approved: false)
      end

      redirect_to admin_comments_path, notice: @comment.approved? ? t("flash.comments.approved") : t("flash.comments.rejected")
    end

    def destroy
      @comment = Comment.find(params[:id])
      @comment.destroy
      redirect_to admin_comments_path, notice: t("flash.comments.deleted")
    end
  end
end
