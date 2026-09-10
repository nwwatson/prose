module Admin
  class BaseController < ApplicationController
    include Authorization

    before_action :require_authentication

    layout "admin"
  end
end
