class HandlesController < ApplicationController
  before_action :require_identity

  def update
    if current_identity.update(handle: params[:handle])
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("handle_form", partial: "handles/display", locals: { identity: current_identity }) }
        format.html { redirect_back fallback_location: root_path, notice: t("flash.handles.updated") }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("handle_form", partial: "handles/form", locals: { identity: current_identity }) }
        format.html { redirect_back fallback_location: root_path, alert: t("flash.handles.could_not_update") }
      end
    end
  end
end
