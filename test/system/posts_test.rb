# frozen_string_literal: true

require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  setup do
    @account = accounts(:one)
    @publication = publications(:one)
    @post = posts(:one)
  end

  test "should create new post" do
    visit publication_url(@publication)
    click_on "New Post"

    fill_in "Title", with: "My Amazing Blog Post"

    # Fill in content using rich text editor
    find("trix-editor").set("This is the content of my amazing blog post. It has rich text formatting and everything!")

    fill_in "Summary", with: "This is a summary of my blog post"
    select "draft", from: "Status"

    # SEO fields
    fill_in "Meta Title", with: "Amazing Blog Post - SEO Title"
    fill_in "Meta Description", with: "This is the meta description for SEO purposes"

    # Check featured and pinned
    check "Featured post"
    check "Pin to top"

    click_on "Create Post"

    assert_text "Post was successfully created"
    assert_selector "h1", text: "My Amazing Blog Post"
    assert_text "This is a summary of my blog post"
  end

  test "should edit existing post" do
    visit publication_post_url(@publication, @post)
    click_on "Edit"

    fill_in "Title", with: "Updated Post Title"
    fill_in "Summary", with: "Updated summary text"
    select "published", from: "Status"

    click_on "Update Post"

    assert_text "Post was successfully updated"
    assert_selector "h1", text: "Updated Post Title"
    assert_text "Updated summary text"
  end

  test "should schedule post for future publication" do
    visit new_publication_post_url(@publication)

    fill_in "Title", with: "Scheduled Future Post"
    find("trix-editor").set("This post will be published in the future")

    select "scheduled", from: "Status"

    # The scheduled date field should appear
    assert_selector "#scheduled-at-field", visible: true

    # Set a future date
    future_date = 1.day.from_now.strftime("%Y-%m-%dT%H:%M")
    fill_in "post_scheduled_at", with: future_date

    click_on "Create Post"

    assert_text "Post was successfully created"
    assert_text "Scheduled for"
  end

  test "should publish draft post" do
    # Create a draft post first
    draft_post = @publication.posts.create!(
      title: "Draft Post",
      content: "This is a draft",
      status: "draft"
    )

    visit publication_post_url(@publication, draft_post)

    click_button "Publish Now"

    assert_text "Post was successfully published"
    assert_selector ".bg-green-100", text: "Published"
  end

  test "should unpublish published post" do
    # Create a published post
    published_post = @publication.posts.create!(
      title: "Published Post",
      content: "This is published",
      status: "published",
      published_at: Time.current
    )

    visit publication_post_url(@publication, published_post)

    accept_confirm do
      click_button "Unpublish"
    end

    assert_text "Post was unpublished"
    assert_selector ".bg-yellow-100", text: "Draft"
  end

  test "should preview post" do
    visit publication_post_url(@publication, @post)

    click_on "Preview"

    # Should open in new tab/window and show preview layout
    switch_to_window windows.last

    assert_text "Preview Mode"
    assert_selector "article"
    assert_selector "h1", text: @post.title
  end

  test "should handle featured image upload" do
    visit new_publication_post_url(@publication)

    fill_in "Title", with: "Post with Image"
    find("trix-editor").set("Content for post with image")

    attach_file "Featured image", Rails.root.join("test", "fixtures", "files", "test.png")

    click_on "Create Post"

    assert_text "Post was successfully created"
    # Featured image should be displayed
    assert_selector "img"
  end

  test "should show validation errors" do
    visit new_publication_post_url(@publication)

    # Submit without required title
    click_on "Create Post"

    assert_text "Title can't be blank"
    assert_selector ".text-red-700"
  end

  test "should delete post" do
    visit publication_post_url(@publication, @post)
    click_on "Edit"

    accept_confirm do
      click_on "Delete Post"
    end

    assert_text "Post was successfully deleted"
    assert_current_path publication_path(@publication)
  end

  test "should handle status change UI" do
    visit edit_publication_post_url(@publication, @post)

    # Check that scheduled field is hidden initially
    assert_selector "#scheduled-at-field", visible: false

    # Change to scheduled
    select "scheduled", from: "Status"

    # Field should become visible
    assert_selector "#scheduled-at-field", visible: true

    # Change back to draft
    select "draft", from: "Status"

    # Field should be hidden again
    assert_selector "#scheduled-at-field", visible: false
  end

  test "should show post details and stats" do
    @post.update!(view_count: 42, reading_time: 7)

    visit publication_post_url(@publication, @post)

    assert_text "42"  # view count
    assert_text "7 min read"
    assert_text "Status:"
    assert_text "Reading time:"
    assert_text "Word count:"
  end

  test "should handle breadcrumb navigation" do
    visit publication_post_url(@publication, @post)

    assert_selector "a", text: @publication.name
    click_on @publication.name

    assert_current_path publication_path(@publication)
  end

  test "should display featured and pinned badges" do
    @post.update!(featured: true, pinned: true)

    visit publication_post_url(@publication, @post)

    assert_text "⭐ Featured"
    assert_text "📌 Pinned"
  end

  test "should handle SEO fields and preview" do
    @post.update!(
      meta_title: "Custom SEO Title",
      meta_description: "Custom SEO description for this post"
    )

    visit publication_post_url(@publication, @post)

    assert_text "SEO Preview"
    assert_text "Custom SEO Title"
    assert_text "Custom SEO description"
  end

  test "should show proper status badges" do
    # Test different status badges
    statuses = {
      "published" => "bg-green-100",
      "draft" => "bg-yellow-100",
      "scheduled" => "bg-blue-100",
      "archived" => "bg-gray-100"
    }

    statuses.each do |status, css_class|
      @post.update!(status: status)
      visit publication_post_url(@publication, @post)

      assert_selector ".#{css_class}", text: status.humanize
    end
  end

  test "should handle rich text content editing" do
    visit edit_publication_post_url(@publication, @post)

    # Clear existing content and add new content
    editor = find("trix-editor")
    editor.set("This is new rich text content with **bold** and *italic* text.")

    click_on "Update Post"

    assert_text "Post was successfully updated"
    # Content should be preserved
    assert_text "This is new rich text content"
  end

  test "navigation and cancel buttons work correctly" do
    # Test navigation from various states
    visit new_publication_post_url(@publication)
    click_on "Cancel"
    assert_current_path publication_path(@publication)

    visit edit_publication_post_url(@publication, @post)
    click_on "Cancel"
    assert_current_path publication_post_path(@publication, @post)

    visit publication_post_url(@publication, @post)
    click_on "Back to Publication"
    assert_current_path publication_path(@publication)
  end
end
