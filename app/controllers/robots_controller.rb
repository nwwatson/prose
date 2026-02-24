class RobotsController < ApplicationController
  def index
    @block_crawlers = SiteSetting.current.block_crawlers?

    respond_to do |format|
      format.text
    end
  end
end
