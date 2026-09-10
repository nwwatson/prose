module Admin
  module EditorResource
    extend ActiveSupport::Concern

    included do
      layout :choose_layout
      class_attribute :editor_layout, default: "admin"
    end

    class_methods do
      def uses_editor_layout(name)
        self.editor_layout = name
      end
    end

    private

    def choose_layout
      action_name.in?(%w[new edit create update]) ? editor_layout : "admin"
    end

    def respond_with_saved(record, notice:, status:)
      respond_to do |format|
        format.html { redirect_to edit_path_for(record), notice: notice }
        format.json { render json: resource_json(record), status: status }
      end
    end

    def respond_with_errors(record, template)
      respond_to do |format|
        format.html { render template, status: :unprocessable_entity }
        format.json { render json: { errors: record.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end
