require "test_helper"

class ActiveRecordTranslationsTest < ActiveSupport::TestCase
  test "validation messages are Spanish on a Spanish site" do
    I18n.with_locale(:es) do
      category = Category.new
      category.valid?
      assert_includes category.errors.full_messages, "Nombre no puede estar en blanco"

      webhook = Webhook.new(url: "http://localhost/hook", events: [ "nope" ])
      webhook.valid?
      assert_includes webhook.errors.full_messages, "URL no debe apuntar a una dirección de red local, privada o reservada"
      assert_includes webhook.errors.full_messages, "Eventos contiene tipos de evento desconocidos: nope"
    end
  end

  test "custom validation messages read as before in English" do
    label = SubscriberLabel.new(name: "x", color: "red")
    label.valid?
    assert_includes label.errors.full_messages, "Color must be a valid hex color (e.g. #6B7280)"

    page = Page.new(title: "Feed", slug: "feed")
    page.valid?
    assert_includes page.errors.full_messages, "Slug is reserved"
  end

  # rails-i18n isn't bundled, so a message Rails adds has to be added here too.
  test "every default Active Model and Active Record error message is translated" do
    %w[activemodel activerecord].each do |gem_name|
      path = Dir[File.join(Gem.loaded_specs.fetch(gem_name).full_gem_path, "lib/**/locale/en.yml")].first
      defaults = YAML.load_file(path).fetch("en")
      keys = defaults.dig("errors", "messages").keys.map { |key| "errors.messages.#{key}" }
      keys += Array(defaults.dig("activerecord", "errors", "messages")&.keys).map { |key| "activerecord.errors.messages.#{key}" }

      keys.each do |key|
        assert I18n.exists?(key, :es, fallback: false), "es.yml is missing #{key}"
      end
    end
  end

  test "translated model and attribute names refer to real models and attributes" do
    Rails.application.eager_load!
    models = ApplicationRecord.descendants.index_by { |model| model.model_name.i18n_key }

    I18n.t("activerecord.models", locale: :es).each_key do |key|
      assert models.key?(key), "no model for #{key}"
    end

    I18n.t("activerecord.attributes", locale: :es).each do |key, attributes|
      model = models.fetch(key)
      attributes.each_key do |name|
        known = model.attribute_names.include?(name.to_s) || model.method_defined?(name) || model.reflect_on_association(name)
        assert known, "#{key} has no attribute #{name}"
      end
    end
  end
end
