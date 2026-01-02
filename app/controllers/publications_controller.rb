# frozen_string_literal: true

class PublicationsController < ApplicationController
  before_action :set_publication, only: %i[ show edit update destroy ]
  before_action :set_account, except: [ :index ]

  def index
    @publications = current_user.publications.includes(:account)

    # Redirect to accounts if no publications exist
    if @publications.empty? && current_user.accounts.empty?
      redirect_to new_account_path, notice: "Please create an account first."
    elsif @publications.empty?
      redirect_to accounts_path, notice: "Create your first publication."
    end
  end

  def show
  end

  def new
    @publication = @account.publications.build
  end

  def create
    @publication = @account.publications.build(publication_params)

    if @publication.save
      redirect_to [ @account, @publication ], notice: "Publication was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @publication.update(publication_params)
      redirect_to [ @account, @publication ], notice: "Publication was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @publication.destroy!
    redirect_to @account, notice: "Publication was successfully deleted."
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id]) if params[:account_id]
  end

  def set_publication
    if @account
      @publication = @account.publications.find(params[:id])
    else
      @publication = current_user.publications.find(params[:id])
    end
  end

  def publication_params
    params.require(:publication).permit(
      :name,
      :tagline,
      :description,
      :custom_domain,
      :custom_css,
      :language,
      :timezone,
      :active,
      :favicon,
      :logo,
      :header_image,
      settings: [
        :allow_comments,
        :require_subscription,
        :show_author_bio,
        :email_footer,
        :analytics_code
      ],
      social_links: [
        :twitter,
        :facebook,
        :instagram,
        :linkedin,
        :github,
        :website
      ]
    )
  end
end
