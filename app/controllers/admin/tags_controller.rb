module Admin
  class TagsController < BaseController
    def create
      tag = Tag.find_or_initialize_by(name: tag_params[:name].strip)

      if tag.save
        render json: { id: tag.id, name: tag.name, slug: tag.slug }
      else
        render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def tag_params
      params.require(:tag).permit(:name)
    end
  end
end
