class CommentsController < ApplicationController
  before_action :require_identity
  before_action :set_post
  before_action :set_comment, only: [ :update, :destroy ]
  before_action :authorize_edit, only: :update
  before_action :authorize_delete, only: :destroy

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

  def update
    if @comment.update(body: comment_params[:body], edited_at: Time.current)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "comments/comment", locals: { comment: @comment }) }
        format.html { redirect_to post_path(@post, slug: @post.slug, anchor: "comment_#{@comment.id}") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("edit_comment_#{@comment.id}", partial: "comments/edit_form", locals: { post: @post, comment: @comment }) }
        format.html { redirect_to post_path(@post, slug: @post.slug), alert: t("flash.comments.could_not_save") }
      end
    end
  end

  def destroy
    @comment.soft_delete!

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("comment_#{@comment.id}", partial: "comments/comment", locals: { comment: @comment }) }
      format.html { redirect_to post_path(@post, slug: @post.slug), notice: t("flash.comments.deleted") }
    end
  end

  private

  def set_post
    @post = Post.live.find_by!(slug: params[:post_slug])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def authorize_edit
    unless @comment.editable_by?(current_identity)
      redirect_to post_path(@post, slug: @post.slug), alert: t("flash.comments.cannot_edit")
    end
  end

  def authorize_delete
    unless @comment.deletable_by?(current_identity)
      redirect_to post_path(@post, slug: @post.slug), alert: t("flash.comments.cannot_delete")
    end
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_comment_id, :notify_on_reply)
  end
end
