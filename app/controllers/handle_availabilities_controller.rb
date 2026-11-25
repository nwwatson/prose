class HandleAvailabilitiesController < ApplicationController
  def show
    handle = params[:handle].to_s.strip.downcase
    available = handle.length >= 3 && !Identity.where.not(id: current_identity&.id).exists?(handle: handle)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("handle_availability", html: availability_badge(available))
      end
      format.json { render json: { available: available } }
    end
  end

  private

  def availability_badge(available)
    key, color = available ? [ "available", "text-green-600" ] : [ "taken", "text-red-600" ]

    helpers.tag.span(t("handles.availability.#{key}"), id: "handle_availability", class: "text-sm #{color}")
  end
end
