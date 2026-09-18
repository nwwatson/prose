module Admin
  class NavigationItemsController < BaseController
    before_action :require_admin
    before_action :set_item, only: [ :edit, :update, :destroy, :move ]

    def index
      load_sections
    end

    def create
      item = NavigationItem.new(item_params)

      if item.save
        redirect_to admin_navigation_items_path(anchor: item.location), notice: t("flash.admin.navigation_items.created")
      else
        load_sections(item.location => item)
        render :index, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @item.update(item_params)
        redirect_to admin_navigation_items_path(anchor: @item.location), notice: t("flash.admin.navigation_items.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @item.destroy
      redirect_to admin_navigation_items_path(anchor: @item.location), notice: t("flash.admin.navigation_items.deleted")
    end

    # Keyboard/no-JS fallback for drag-and-drop: swaps with the neighbouring item.
    def move
      @item.move(params[:direction])
      redirect_to admin_navigation_items_path(anchor: @item.location)
    end

    # Called by the sortable Stimulus controller after a drag-and-drop.
    def reorder
      location = params.require(:location)
      return head :unprocessable_entity unless NavigationItem.locations.key?(location)

      NavigationItem.reposition!(location, Array(params[:ids]))
      head :no_content
    end

    private

    def set_item
      @item = NavigationItem.find(params[:id])
    end

    def item_params
      params.require(:navigation_item).permit(:label, :url, :location, :open_in_new_tab)
    end

    # @sections maps each location to its ordered items; @new_items holds the
    # blank (or failed) add-form record per location.
    def load_sections(new_items = {})
      grouped = NavigationItem.ordered.group_by(&:location)
      @sections = NavigationItem.locations.keys.index_with { |location| grouped.fetch(location, []) }
      @new_items = NavigationItem.locations.keys.index_with do |location|
        new_items[location] || NavigationItem.new(location: location)
      end
    end
  end
end
