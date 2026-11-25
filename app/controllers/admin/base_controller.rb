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

    # Narrows +scope+ by the model scope that +value+ names. +allowed+ lists the
    # accepted values, or maps each to a differently named scope; anything else
    # is ignored.
    def filter_by_status(scope, allowed, value: params[:status])
      scopes = allowed.is_a?(Hash) ? allowed : allowed.index_by(&:itself)
      name = scopes[value]

      name ? scope.public_send(name) : scope
    end
  end
end
