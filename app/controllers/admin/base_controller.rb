module Admin
  class BaseController < ApplicationController
    include Authentication
    include Authorization
    include ::Ai::Configurable

    before_action :require_authentication, :configure_ruby_llm!

    layout "admin"
  end
end
