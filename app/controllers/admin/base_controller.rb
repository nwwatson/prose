module Admin
  class BaseController < ApplicationController
    include Authentication
    include Authorization

    before_action :require_authentication

    layout "admin"
  end
end
