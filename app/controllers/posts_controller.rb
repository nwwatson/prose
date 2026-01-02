# frozen_string_literal: true

class PostsController < ApplicationController
  before_action :set_publication
  before_action :set_post, only: %i[ show edit update destroy preview publish unpublish ]

  def show
  end

  def new
    @post = @publication.posts.build
    @post.status = "draft"
  end

  def create
    @post = @publication.posts.build(post_params)

    if @post.save
      redirect_to [ @publication, @post ], notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      redirect_to [ @publication, @post ], notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    redirect_to @publication, notice: "Post was successfully deleted."
  end

  def preview
    render layout: "preview"
  end

  def publish
    if @post.publish!
      redirect_to [ @publication, @post ], notice: "Post was successfully published."
    else
      redirect_to [ @publication, @post ], alert: "Could not publish post."
    end
  end

  def unpublish
    if @post.unpublish!
      redirect_to [ @publication, @post ], notice: "Post was unpublished."
    else
      redirect_to [ @publication, @post ], alert: "Could not unpublish post."
    end
  end

  private

  def set_publication
    @publication = Publication.find(params[:publication_id])
  end

  def set_post
    @post = @publication.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(
      :title,
      :content,
      :summary,
      :status,
      :scheduled_at,
      :meta_title,
      :meta_description,
      :featured,
      :pinned,
      :featured_image
    )
  end
end
