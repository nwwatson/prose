module Paginatable
  extend ActiveSupport::Concern

  private

  def paginate(scope, per_page: 10)
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    offset = (@page - 1) * per_page

    @next_page = @page + 1 if scope.offset(offset + per_page).exists?
    scope.offset(offset).limit(per_page)
  end

  # Infinite scroll (posts/_post_page) loads the next page into a
  # "posts_page_<n>" turbo frame; Turbo only keeps that frame from the response.
  def post_page_frame_request?
    turbo_frame_request_id.to_s.start_with?("posts_page_")
  end
end
