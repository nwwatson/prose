require "test_helper"

class Exports::JsonExporterTest < ActiveSupport::TestCase
  setup do
    SiteSetting.current.update!(
      site_name: "Export Test Site",
      claude_api_key: "sk-ant-secret",
      stripe_secret_key: "sk_live_secret",
      sendgrid_api_key: "SG.secret"
    )
    posts(:published_post).update!(content: "<p>Exported <em>body</em></p>")
  end

  test "call writes valid JSON to a rewound tempfile" do
    tempfile = Exports::JsonExporter.call
    data = JSON.parse(tempfile.read)

    assert_equal "prose", data["format"]
    assert_equal Exports::JsonExporter::FORMAT_VERSION, data["version"]
  ensure
    tempfile&.close!
  end

  test "includes every top-level collection" do
    data = export_data

    assert_equal "Export Test Site", data.dig("site", "site_name")
    assert_equal User.count, data["authors"].size
    assert_equal Category.count, data["categories"].size
    assert_equal Tag.count, data["tags"].size
    assert_equal Post.count, data["posts"].size
    assert_equal Page.count, data["pages"].size
    assert_equal NavigationItem.count, data["navigation_items"].size
    assert_equal Subscriber.count, data["subscribers"].size
    assert_equal SubscriberLabel.count, data["subscriber_labels"].size
  end

  test "posts include html content and tag ids" do
    post = posts(:published_post)
    exported = export_data["posts"].find { |p| p["id"] == post.id }

    assert_includes exported["content_html"], "Exported <em>body</em>"
    assert_equal post.tags.pluck(:id).sort, exported["tag_ids"]
    assert_equal "published", exported["status"]
  end

  test "navigation items include location, order and new-tab flag" do
    github = export_data["navigation_items"].find { |item| item["label"] == "GitHub" }

    assert_equal({ "label" => "GitHub", "url" => "https://github.com/prose", "location" => "social", "position" => 0, "open_in_new_tab" => true }, github)
  end

  test "subscribers include email and label ids" do
    subscriber = subscribers(:confirmed)
    exported = export_data["subscribers"].find { |s| s["id"] == subscriber.id }

    assert_equal subscriber.email, exported["email"]
    assert_equal subscriber.subscriber_labels.pluck(:id).sort, exported["label_ids"]
  end

  test "never includes secrets, password digests or auth tokens" do
    json = JSON.generate(export_data)

    SiteSetting::SECRET_ATTRIBUTES.each { |attribute| assert_not_includes export_data["site"].keys, attribute }
    assert_not_includes json, "sk-ant-secret"
    assert_not_includes json, "sk_live_secret"
    assert_not_includes json, "SG.secret"
    assert_not_includes json, "password_digest"
    assert_not_includes json, "auth_token"
    assert_not_includes json, users(:admin).password_digest
  end

  test "every allowlisted site setting attribute exists" do
    missing = Exports::JsonExporter::SITE_SETTING_ATTRIBUTES - SiteSetting.column_names
    assert_empty missing
  end

  private

  def export_data
    @export_data ||= JSON.parse(JSON.generate(Exports::JsonExporter.new.as_json))
  end
end
