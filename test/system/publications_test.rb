# frozen_string_literal: true

require "application_system_test_case"

class PublicationsTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:one)
    @publication = publications(:one)
  end

  test "visiting the index" do
    visit publications_url
    assert_selector "h1", text: "Publications"
    assert_selector "a", text: "New Publication"
  end

  test "should create publication" do
    visit publications_url
    click_on "New Publication"

    fill_in "Name", with: "My Test Newsletter"
    fill_in "Tagline", with: "A great newsletter for testing"
    fill_in "Description", with: "This is a comprehensive description of my newsletter"
    select @account.name, from: "Account"
    fill_in "Custom domain", with: "newsletter.example.com"

    # Fill in social links
    fill_in "social_links[twitter]", with: "https://twitter.com/testnewsletter"
    fill_in "social_links[website]", with: "https://testnewsletter.com"

    # Configure settings
    check "Allow comments on posts"
    uncheck "Require subscription to read posts"
    fill_in "settings[email_footer]", with: "Thanks for subscribing to our newsletter!"

    click_on "Create Publication"

    assert_text "Publication was successfully created"
    assert_selector "h1", text: "My Test Newsletter"
    assert_text "A great newsletter for testing"
    assert_text "newsletter.example.com"
  end

  test "should update Publication" do
    visit publication_url(@publication)
    click_on "Edit"

    fill_in "Name", with: "Updated Publication Name"
    fill_in "Tagline", with: "Updated tagline"
    fill_in "Custom CSS", with: ".header { color: blue; }"

    # Update settings
    uncheck "Publication is active"
    fill_in "settings[analytics_code]", with: "GA-123456789"

    click_on "Update Publication"

    assert_text "Publication was successfully updated"
    assert_selector "h1", text: "Updated Publication Name"
    assert_text "Updated tagline"
  end

  test "should delete Publication" do
    visit publication_url(@publication)
    click_on "Edit"

    accept_confirm do
      click_on "Delete", match: :first
    end

    assert_text "Publication was successfully deleted"
    assert_current_path publications_path
  end

  test "should show validation errors" do
    visit publications_url
    click_on "New Publication"

    # Submit form without required fields
    click_on "Create Publication"

    assert_text "Name can't be blank"
    assert_selector ".text-red-700"
  end

  test "should show publication details and stats" do
    # Create some posts for the publication to show stats
    post1 = @publication.posts.create!(
      title: "First Post",
      content: "Content here",
      status: "published",
      view_count: 100
    )
    post2 = @publication.posts.create!(
      title: "Second Post",
      content: "More content",
      status: "draft",
      view_count: 50
    )

    visit publication_url(@publication)

    # Check publication details are displayed
    assert_selector "h1", text: @publication.name
    if @publication.tagline.present?
      assert_text @publication.tagline
    end

    # Check stats are displayed
    assert_text "Total Posts"
    assert_text "Published"
    assert_text "Drafts"
    assert_text "Total Views"

    # Check recent posts are shown
    assert_text "Recent Posts"
    assert_text post1.title
    assert_text post2.title
  end

  test "should handle empty publications list" do
    Publication.destroy_all

    visit publications_url

    assert_text "No publications"
    assert_text "Get started by creating a new publication"
    assert_selector "a", text: "New Publication"
  end

  test "should show social links when available" do
    @publication.update!(
      social_links: {
        "twitter" => "https://twitter.com/test",
        "website" => "https://example.com"
      }
    )

    visit publication_url(@publication)

    assert_text "Social Links"
    assert_selector "a[href='https://twitter.com/test']"
    assert_selector "a[href='https://example.com']"
  end

  test "should handle custom domain display" do
    @publication.update!(custom_domain: "newsletter.example.com")

    visit publication_url(@publication)

    assert_text "newsletter.example.com"
    assert_text "Custom Domain"
  end

  test "should show settings information" do
    @publication.update!(
      settings: {
        "allow_comments" => true,
        "require_subscription" => false,
        "show_author_bio" => true
      },
      language: "es",
      timezone: "America/New_York"
    )

    visit publication_url(@publication)

    assert_text "Settings"
    assert_text "ES"
    assert_text "America/New_York"
  end

  test "navigation and links work correctly" do
    visit publications_url

    # Test navigation to new publication
    click_on "New Publication"
    assert_current_path new_publication_path

    # Test back navigation
    click_on "Back to Publications"
    assert_current_path publications_path

    # Test view publication
    click_on @publication.name
    assert_current_path publication_path(@publication)

    # Test edit navigation
    click_on "Edit"
    assert_current_path edit_publication_path(@publication)

    # Test cancel navigation
    click_on "Cancel"
    assert_current_path publication_path(@publication)
  end
end
