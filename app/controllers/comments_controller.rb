class CommentsController < ApplicationController
  before_action :require_identity
  include LivePostScoped
  before_action :set_comment, only: [ :update, :destroy ]
  before_action :authorize_edit, only: :update
  before_action :authorize_delete, only: :destroy

  def create
    @comment = @post.comments.build(comment_params)
    @comment.identity = current_identity

    if @comment.save
      render_comment :append, "comments", anchor: "comment_#{@comment.id}"
    else
      render_comment :replace, "comment_form", partial: "comments/form", alert: t("flash.comments.could_not_save")
    end
  end

  def update
    if @comment.update(body: comment_params[:body], edited_at: Time.current)
      render_comment :replace, "comment_#{@comment.id}", anchor: "comment_#{@comment.id}"
    else
      render_comment :replace, "edit_comment_#{@comment.id}", partial: "comments/edit_form", alert: t("flash.comments.could_not_save")
    end
  end

  def destroy
    @comment.soft_delete!
    render_comment :replace, "comment_#{@comment.id}", notice: t("flash.comments.deleted")
  end

  private

  # Turbo requests get a stream applying +partial+ to +target+; others are sent
  # back to the post with +flash+.
  def render_comment(action, target, partial: "comments/comment", anchor: nil, **flash)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.public_send(action, target, partial: partial, locals: { comment: @comment, post: @post }) }
      format.html { redirect_to post_path(slug: @post.slug, anchor: anchor), **flash }
    end
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def authorize_edit
    unless @comment.editable_by?(current_identity)
      redirect_to post_path(slug: @post.slug), alert: t("flash.comments.cannot_edit")
    end
  end

  def authorize_delete
    unless @comment.deletable_by?(current_identity)
      redirect_to post_path(slug: @post.slug), alert: t("flash.comments.cannot_delete")
    end
  end

  def comment_params
    params.require(:comment).permit(:body, :parent_comment_id, :notify_on_reply)
  end
end
