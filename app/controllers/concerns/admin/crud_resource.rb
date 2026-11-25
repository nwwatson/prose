module Admin
  # The new/create/edit/update/destroy actions shared by the plain admin
  # resources. A controller declares its model with +crud_resource+ and defines
  # +resource_params+. The record is exposed to views as @<model name> (or @<as>).
  #
  # Override points: +find_resource+, +after_save_path+, or any action. +create+
  # yields after a successful save, so a controller can add to the flash with
  # <tt>super { ... }</tt>.
  module CrudResource
    extend ActiveSupport::Concern

    included do
      class_attribute :resource_class, :resource_name, :resource_flash_scope, instance_accessor: false, instance_predicate: false
    end

    class_methods do
      # +member_actions+ are extra actions that need the record loaded.
      def crud_resource(model, as: model.model_name.element, flash_scope: "flash.admin.#{model.model_name.plural}", member_actions: [])
        self.resource_class = model
        self.resource_name = as.to_s
        self.resource_flash_scope = flash_scope

        before_action :set_resource, only: [ :edit, :update, :destroy, *member_actions ]
      end
    end

    def new
      self.resource = self.class.resource_class.new
    end

    def create
      self.resource = self.class.resource_class.new(resource_params)

      if resource.save
        yield if block_given?
        redirect_to after_save_path, notice: crud_notice(:created)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if resource.update(resource_params)
        redirect_to after_save_path, notice: crud_notice(:updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      resource.destroy
      redirect_to index_path, notice: crud_notice(:deleted)
    end

    private

    def resource
      instance_variable_get("@#{self.class.resource_name}")
    end

    def resource=(record)
      instance_variable_set("@#{self.class.resource_name}", record)
    end

    def set_resource
      self.resource = find_resource
    end

    def find_resource
      self.class.resource_class.find(params[:id])
    end

    def index_path
      polymorphic_path([ :admin, self.class.resource_class ])
    end

    def after_save_path
      index_path
    end

    def crud_notice(key)
      t("#{self.class.resource_flash_scope}.#{key}")
    end
  end
end
