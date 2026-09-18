module ActivityPub
  class ActorsController < BaseController
    def show
      render_activity ActorSerializer.call
    end
  end
end
