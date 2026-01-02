# frozen_string_literal: true

require "test_helper"

class PublicationTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(name: "Test Account")
    @publication = Publication.new(
      name: "Test Publication",
      tagline: "A test publication",
      account: @account
    )
  end

  test "should be valid with valid attributes" do
    assert @publication.valid?
  end

  test "should require name" do
    @publication.name = nil
    assert_not @publication.valid?
    assert_includes @publication.errors[:name], "can't be blank"
  end

  test "should require account" do
    @publication.account = nil
    assert_not @publication.valid?
    assert_includes @publication.errors[:account], "must exist"
  end

  test "should generate slug from name on creation" do
    @publication.save!
    assert_equal "test-publication", @publication.slug
  end

  test "should generate unique slug when duplicate name exists" do
    @publication.save!

    duplicate = Publication.new(
      name: "Test Publication",
      account: @account
    )
    duplicate.save!

    assert_equal "test-publication-1", duplicate.slug
  end

  test "should validate name length" do
    @publication.name = "a" * 101
    assert_not @publication.valid?
    assert_includes @publication.errors[:name], "is too long (maximum is 100 characters)"
  end

  test "should validate tagline length" do
    @publication.tagline = "a" * 201
    assert_not @publication.valid?
    assert_includes @publication.errors[:tagline], "is too long (maximum is 200 characters)"
  end

  test "should validate description length" do
    @publication.description = "a" * 2001
    assert_not @publication.valid?
    assert_includes @publication.errors[:description], "is too long (maximum is 2000 characters)"
  end

  test "should validate custom domain format" do
    @publication.custom_domain = "invalid-domain"
    assert_not @publication.valid?
    assert_includes @publication.errors[:custom_domain], "must be a valid domain"
  end

  test "should accept valid custom domain" do
    @publication.custom_domain = "example.com"
    assert @publication.valid?
  end

  test "should allow blank custom domain" do
    @publication.custom_domain = ""
    assert @publication.valid?
  end

  test "should validate custom domain uniqueness" do
    @publication.custom_domain = "example.com"
    @publication.save!

    duplicate = Publication.new(
      name: "Another Publication",
      custom_domain: "example.com",
      account: @account
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:custom_domain], "has already been taken"
  end

  test "should validate language inclusion" do
    @publication.language = "invalid"
    assert_not @publication.valid?
    assert_includes @publication.errors[:language], "is not included in the list"
  end

  test "should accept valid languages" do
    %w[en es fr de pt it].each do |lang|
      @publication.language = lang
      assert @publication.valid?, "Should accept language: #{lang}"
    end
  end

  test "should validate timezone inclusion" do
    @publication.timezone = "Invalid/Timezone"
    assert_not @publication.valid?
    assert_includes @publication.errors[:timezone], "is not included in the list"
  end

  test "should accept valid timezone" do
    @publication.timezone = "America/New_York"
    assert @publication.valid?
  end

  test "should have default values" do
    publication = Publication.create!(name: "Test", account: @account)

    assert_equal "en", publication.language
    assert_equal "UTC", publication.timezone
    assert publication.active?
  end

  test "should initialize default settings" do
    publication = Publication.new(name: "Test", account: @account)

    expected_settings = {
      "allow_comments" => true,
      "require_subscription" => false,
      "show_author_bio" => true,
      "email_footer" => "",
      "analytics_code" => ""
    }

    assert_equal expected_settings, publication.settings
    assert_equal({}, publication.social_links)
  end

  test "should provide access to individual settings" do
    @publication.save!
    assert @publication.setting("allow_comments")
    assert_not @publication.setting("require_subscription")
  end

  test "should update individual settings" do
    @publication.save!
    @publication.update_setting("allow_comments", false)

    @publication.reload
    assert_not @publication.setting("allow_comments")
  end

  test "should provide access to social links" do
    @publication.social_links = { "twitter" => "https://twitter.com/test" }
    @publication.save!

    assert_equal "https://twitter.com/test", @publication.social_link(:twitter)
    assert_equal "https://twitter.com/test", @publication.social_link("twitter")
    assert_nil @publication.social_link(:facebook)
  end

  test "should return primary domain" do
    @publication.save!
    assert_equal "test-publication.prose.local", @publication.primary_domain

    @publication.update!(custom_domain: "example.com")
    assert_equal "example.com", @publication.primary_domain
  end

  test "should return default subdomain" do
    @publication.save!
    assert_equal "test-publication.prose.local", @publication.default_subdomain
  end

  test "should use slug for to_param" do
    @publication.save!
    assert_equal "test-publication", @publication.to_param
  end

  # Scope tests
  test "active scope should return active publications" do
    active_pub = Publication.create!(name: "Active", account: @account, active: true)
    inactive_pub = Publication.create!(name: "Inactive", account: @account, active: false)

    assert_includes Publication.active, active_pub
    assert_not_includes Publication.active, inactive_pub
  end

  test "with_custom_domain scope should return publications with custom domains" do
    with_domain = Publication.create!(name: "With Domain", account: @account, custom_domain: "example.com")
    without_domain = Publication.create!(name: "Without Domain", account: @account)

    assert_includes Publication.with_custom_domain, with_domain
    assert_not_includes Publication.with_custom_domain, without_domain
  end

  # Association tests
  test "should support file attachments" do
    @publication.save!

    assert_respond_to @publication, :favicon
    assert_respond_to @publication, :logo
    assert_respond_to @publication, :header_image
  end
end
