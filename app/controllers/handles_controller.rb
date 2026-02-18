class HandlesController < ApplicationController
  before_action :require_identity

  def update
    if current_identity.update(handle: params[:handle])
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("handle_form", partial: "handles/display", locals: { identity: current_identity }) }
        format.html { redirect_back fallback_location: root_path, notice: "Handle updated." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("handle_form", partial: "handles/form", locals: { identity: current_identity }) }
        format.html { redirect_back fallback_location: root_path, alert: "Handle could not be updated." }
      end
    end
  end
end
