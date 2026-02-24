class CommentsController < ApplicationController
  before_action :require_identity
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params)
    @comment.identity = current_identity

    if @comment.save
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("comments", partial: "comments/comment", locals: { comment: @comment }) }
        format.html { redirect_to post_path(@post, slug: @post.slug, anchor: "comment_#{@comment.id}") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form", locals: { post: @post, comment: @comment }) }
        format.html { redirect_to post_path(@post, slug: @post.slug), alert: t("flash.comments.could_not_save") }
      end
    end
  end

  private

  def set_post
    @post = Post.live.find_by!(slug: params[:post_slug])
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_comment_id)
  end
end
