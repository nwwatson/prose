# Merges a reader's localStorage reading list into their account the first
# time they load a page signed in, so their list follows them across devices.
class ReadingListImportsController < ApplicationController
  include ReadingListJson

  def create
    current_identity.import_reading_list!(params[:post_ids])
    render_reading_list
  end
end
