module Admin
  class NewslettersController < BaseController
    layout :choose_layout

    before_action :set_newsletter, only: [ :show, :edit, :update, :destroy, :send_newsletter, :schedule, :preview ]

    def index
      @newsletters = Newsletter.includes(:user)

      case params[:status]
      when "sent"
        @newsletters = @newsletters.sent
      when "scheduled"
        @newsletters = @newsletters.scheduled
      when "draft"
        @newsletters = @newsletters.draft
      end

      if params[:search].present?
        @newsletters = @newsletters.search(params[:search])
      end

      @newsletters = @newsletters.by_recency
    end

    def show
      @analytics = NewsletterAnalyticsQuery.new(@newsletter)
      @deliveries = @newsletter.newsletter_deliveries.includes(:subscriber).order(sent_at: :desc)
    end

    def new
      @newsletter = current_user.newsletters.build(status: :draft)
    end

    def create
      @newsletter = current_user.newsletters.build(newsletter_params)

      if @newsletter.save
        respond_to do |format|
          format.html { redirect_to edit_admin_newsletter_path(@newsletter), notice: "Newsletter created." }
          format.json { render json: newsletter_json(@newsletter), status: :created }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: { errors: @newsletter.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def edit
    end

    def update
      if @newsletter.update(newsletter_params)
        respond_to do |format|
          format.html { redirect_to edit_admin_newsletter_path(@newsletter), notice: "Newsletter updated." }
          format.json { render json: newsletter_json(@newsletter), status: :ok }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: { errors: @newsletter.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @newsletter.destroy
      redirect_to admin_newsletters_path, notice: "Newsletter deleted."
    end

    def send_newsletter
      if @newsletter.sendable?
        @newsletter.send_newsletter!
        redirect_to admin_newsletters_path, notice: "Newsletter is being sent."
      else
        redirect_to edit_admin_newsletter_path(@newsletter), alert: "This newsletter cannot be sent."
      end
    end

    def schedule
      scheduled_for = params[:scheduled_for]
      if scheduled_for.present? && @newsletter.sendable?
        @newsletter.schedule!(Time.zone.parse(scheduled_for))
        redirect_to admin_newsletters_path, notice: "Newsletter scheduled."
      else
        redirect_to edit_admin_newsletter_path(@newsletter), alert: "Could not schedule newsletter."
      end
    end

    def preview
      @email_settings = @newsletter.email_settings
      @site_name = @email_settings[:site_name]
      @unsubscribe_url = "#"
      render layout: "newsletter_mailer"
    end

    private

    def set_newsletter
      @newsletter = Newsletter.find(params[:id])
    end

    def newsletter_params
      params.require(:newsletter).permit(:title, :body, :template, :accent_color, :preheader_text)
    end

    def newsletter_json(newsletter)
      {
        id: newsletter.id,
        url: admin_newsletter_path(newsletter),
        edit_url: edit_admin_newsletter_path(newsletter)
      }
    end

    def choose_layout
      action_name.in?(%w[new edit create update]) ? "newsletter_editor" : "admin"
    end
  end
end
