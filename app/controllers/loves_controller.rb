class LovesController < ApplicationController
  before_action :require_identity
  include LivePostScoped

  def create
    @love = @post.loves.find_or_create_by(identity: current_identity)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("love_button_#{@post.id}", partial: "loves/button", locals: { post: @post.reload }) }
      format.html { redirect_to post_path(@post, slug: @post.slug) }
    end
  end

  def destroy
    @love = @post.loves.find_by(identity: current_identity)
    @love&.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("love_button_#{@post.id}", partial: "loves/button", locals: { post: @post.reload }) }
      format.html { redirect_to post_path(@post, slug: @post.slug) }
    end
  end
end
