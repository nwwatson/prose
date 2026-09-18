class ReadingListItemsController < ApplicationController
  include ReadingListJson

  def create
    current_identity.bookmark!(Post.live.find(params[:post_id]))
    render_reading_list(status: :created)
  rescue ActiveRecord::RecordNotFound
    render json: { error: t("reading_list.errors.not_found") }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def destroy
    current_identity.unbookmark!(params[:post_id].to_i)
    render_reading_list
  end
end
