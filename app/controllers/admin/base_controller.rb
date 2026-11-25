module Admin
  class BaseController < ApplicationController
    include Authorization
    include Paginatable

    PER_PAGE = 50

    before_action :require_authentication

    layout "admin"

    private

    def paginate(scope, per_page: PER_PAGE)
      super
    end
  end
end
