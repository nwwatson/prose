module Paginatable
  extend ActiveSupport::Concern

  private

  def paginate(scope, per_page: 10)
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    offset = (@page - 1) * per_page

    @next_page = @page + 1 if scope.offset(offset + per_page).exists?
    scope.offset(offset).limit(per_page)
  end
end
