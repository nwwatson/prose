# frozen_string_literal: true

class PublicationsController < ApplicationController
  before_action :set_publication, only: %i[ show edit update destroy ]

  def index
    @publications = Publication.includes(:account).page(params[:page])
  end

  def show
  end

  def new
    @publication = Publication.new
    # For now, create a default account - in a real app this would be current_user.account
    @accounts = Account.all
  end

  def create
    @publication = Publication.new(publication_params)

    if @publication.save
      redirect_to @publication, notice: "Publication was successfully created."
    else
      @accounts = Account.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @publication.update(publication_params)
      redirect_to @publication, notice: "Publication was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @publication.destroy!
    redirect_to publications_url, notice: "Publication was successfully deleted."
  end

  private

  def set_publication
    @publication = Publication.find(params[:id])
  end

  def publication_params
    params.require(:publication).permit(
      :name, :tagline, :description, :account_id, :custom_domain, :custom_css,
      :language, :timezone, :active, :favicon, :logo, :header_image,
      settings: {}, social_links: {}
    )
  end
end
