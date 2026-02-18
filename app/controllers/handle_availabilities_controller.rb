class HandleAvailabilitiesController < ApplicationController
  def show
    handle = params[:handle].to_s.strip.downcase
    available = handle.length >= 3 && !Identity.where.not(id: current_identity&.id).exists?(handle: handle)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("handle_availability",
          html: available ? '<span id="handle_availability" class="text-sm text-green-600">Available</span>'.html_safe : '<span id="handle_availability" class="text-sm text-red-600">Taken</span>'.html_safe)
      end
      format.json { render json: { available: available } }
    end
  end
end
