require "test_helper"

# en.yml and es.yml must stay in step: a key missing from es.yml silently falls
# back to English, so nothing else would notice.
class LocaleFilesTest < ActiveSupport::TestCase
  test "en.yml and es.yml have identical key sets" do
    en = key_paths("en")
    es = key_paths("es")

    assert_empty en - es, "Missing from es.yml"
    assert_empty es - en, "Missing from en.yml"
  end

  private

  def key_paths(locale)
    flatten(YAML.load_file(Rails.root.join("config/locales/#{locale}.yml")).fetch(locale))
  end

  def flatten(tree, prefix = nil)
    tree.flat_map do |key, value|
      path = [ prefix, key ].compact.join(".")
      value.is_a?(Hash) && value.any? ? flatten(value, path) : [ path ]
    end
  end
end
