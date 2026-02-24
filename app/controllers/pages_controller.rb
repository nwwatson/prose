class PagesController < ApplicationController
  def show
    @page = Page.live.find_by!(slug: params[:slug])
  end
end
