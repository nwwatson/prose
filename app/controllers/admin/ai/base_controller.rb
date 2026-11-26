module Admin
  module Ai
    class BaseController < Admin::BaseController
      include ::Ai::Configurable
      include Admin::PostScoped

      before_action :require_ai_configured
      before_action :configure_ruby_llm!
    end
  end
end
