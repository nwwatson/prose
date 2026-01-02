# frozen_string_literal: true

require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @account = Account.create!(name: "Test Account")
    @publication = Publication.create!(name: "Test Publication", account: @account)
    @post = Post.new(
      title: "Test Post",
      content: "This is test content for the post.",
      publication: @publication
    )
  end

  test "should be valid with valid attributes" do
    assert @post.valid?
  end

  test "should require title" do
    @post.title = nil
    assert_not @post.valid?
    assert_includes @post.errors[:title], "can't be blank"
  end

  test "should require publication" do
    @post.publication = nil
    assert_not @post.valid?
    assert_includes @post.errors[:publication], "must exist"
  end

  test "should generate slug from title on creation" do
    @post.save!
    assert_equal "test-post", @post.slug
  end

  test "should generate unique slug within publication scope" do
    @post.save!

    duplicate = Post.new(
      title: "Test Post",
      content: "Different content",
      publication: @publication
    )
    duplicate.save!

    assert_equal "test-post-1", duplicate.slug
  end

  test "should allow same slug in different publications" do
    another_publication = Publication.create!(
      name: "Another Publication", 
      account: @account
    )
    @post.save!

    same_title_post = Post.new(
      title: "Test Post",
      content: "Same title, different publication",
      publication: another_publication
    )
    same_title_post.save!

    assert_equal "test-post", @post.slug
    assert_equal "test-post", same_title_post.slug
  end

  test "should validate title length" do
    @post.title = "a" * 201
    assert_not @post.valid?
    assert_includes @post.errors[:title], "is too long (maximum is 200 characters)"
  end

  test "should validate summary length" do
    @post.summary = "a" * 501
    assert_not @post.valid?
    assert_includes @post.errors[:summary], "is too long (maximum is 500 characters)"
  end

  test "should validate meta_title length" do
    @post.meta_title = "a" * 61
    assert_not @post.valid?
    assert_includes @post.errors[:meta_title], "is too long (maximum is 60 characters)"
  end

  test "should validate meta_description length" do
    @post.meta_description = "a" * 161
    assert_not @post.valid?
    assert_includes @post.errors[:meta_description], "is too long (maximum is 160 characters)"
  end

  test "should have default values" do
    post = Post.create!(title: "Test", content: "Content", publication: @publication)

    assert_equal "draft", post.status
    assert_equal 0, post.reading_time
    assert_equal 0, post.view_count
    assert_not post.featured?
    assert_not post.pinned?
  end

  test "should calculate reading time on save when content changes" do
    content_text = "word " * 200  # 200 words
    @post.content = content_text
    @post.save!

    # Should be 1 minute (200 words / 200 words per minute, minimum 1)
    assert_equal 1, @post.reading_time
  end

  test "should not recalculate reading time if content unchanged" do
    @post.reading_time = 5
    @post.title = "New Title"  # Change non-content field
    @post.save!

    assert_equal 5, @post.reading_time  # Should remain unchanged
  end

  # Publishing workflow tests
  test "should start as draft" do
    @post.save!
    assert @post.draft?
    assert_not @post.visible?
  end

  test "should publish post" do
    @post.save!
    @post.publish!

    assert @post.published?
    assert @post.visible?
    assert_not_nil @post.published_at
  end

  test "should unpublish post" do
    @post.save!
    @post.publish!
    @post.unpublish!

    assert @post.draft?
    assert_not @post.visible?
    assert_nil @post.published_at
  end

  test "should schedule post" do
    @post.save!
    future_time = 1.day.from_now
    @post.schedule!(future_time)

    assert @post.scheduled?
    assert_equal future_time.to_i, @post.scheduled_at.to_i
  end

  test "should set published_at when status changes to published" do
    @post.save!
    assert_nil @post.published_at

    @post.update!(status: :published)
    assert_not_nil @post.published_at
  end

  test "should not overwrite published_at if already set" do
    original_time = 1.week.ago
    @post.published_at = original_time
    @post.save!

    @post.update!(status: :published)
    assert_equal original_time.to_i, @post.published_at.to_i
  end

  # Scope tests
  test "published scope should return only published posts" do
    draft_post = Post.create!(title: "Draft", content: "Content", publication: @publication)
    published_post = Post.create!(title: "Published", content: "Content", publication: @publication)
    published_post.publish!

    published_posts = Post.published
    assert_includes published_posts, published_post
    assert_not_includes published_posts, draft_post
  end

  test "featured scope should return only featured posts" do
    regular_post = Post.create!(title: "Regular", content: "Content", publication: @publication)
    featured_post = Post.create!(title: "Featured", content: "Content", publication: @publication, featured: true)

    featured_posts = Post.featured
    assert_includes featured_posts, featured_post
    assert_not_includes featured_posts, regular_post
  end

  test "pinned scope should return only pinned posts" do
    regular_post = Post.create!(title: "Regular", content: "Content", publication: @publication)
    pinned_post = Post.create!(title: "Pinned", content: "Content", publication: @publication, pinned: true)

    pinned_posts = Post.pinned
    assert_includes pinned_posts, pinned_post
    assert_not_includes pinned_posts, regular_post
  end

  # Content methods
  test "should return excerpt from summary if present" do
    @post.summary = "This is a custom summary"
    @post.save!

    assert_equal "This is a custom summary", @post.excerpt
  end

  test "should return excerpt from content if no summary" do
    long_content = "This is a very long content " * 20
    @post.content = long_content
    @post.save!

    excerpt = @post.excerpt(50)
    assert excerpt.length <= 53  # 50 + "..."
    assert excerpt.include?("This is a very long content")
  end

  test "should count words in content" do
    @post.content = "One two three four five"
    @post.save!

    assert_equal 5, @post.word_count
  end

  test "should estimate reading time" do
    # 400 words should take 2 minutes at 200 words per minute
    @post.content = "word " * 400
    @post.save!

    assert_equal 2, @post.estimated_reading_time
  end

  test "should have minimum reading time of 1 minute" do
    @post.content = "short"
    @post.save!

    assert_equal 1, @post.estimated_reading_time
  end

  # SEO methods
  test "should return meta_title as seo_title if present" do
    @post.meta_title = "Custom SEO Title"
    @post.save!

    assert_equal "Custom SEO Title", @post.seo_title
  end

  test "should fallback to title for seo_title" do
    @post.save!
    assert_equal "Test Post", @post.seo_title
  end

  test "should return meta_description as seo_description if present" do
    @post.meta_description = "Custom SEO description"
    @post.save!

    assert_equal "Custom SEO description", @post.seo_description
  end

  test "should fallback to excerpt for seo_description" do
    @post.content = "This is the post content for SEO description test"
    @post.save!

    seo_desc = @post.seo_description
    assert seo_desc.include?("This is the post content")
    assert seo_desc.length <= 160
  end

  # Action methods
  test "should increment view count" do
    @post.save!
    original_count = @post.view_count

    @post.increment_view_count!
    assert_equal original_count + 1, @post.view_count
  end

  test "should toggle featured status" do
    @post.save!
    assert_not @post.featured?

    @post.toggle_featured!
    assert @post.featured?

    @post.toggle_featured!
    assert_not @post.featured?
  end

  test "should toggle pinned status" do
    @post.save!
    assert_not @post.pinned?

    @post.toggle_pinned!
    assert @post.pinned?

    @post.toggle_pinned!
    assert_not @post.pinned?
  end

  # Association tests
  test "should support rich text content" do
    @post.save!
    assert_respond_to @post, :content
    assert @post.content.is_a?(ActionText::RichText)
  end

  test "should support featured image attachment" do
    @post.save!
    assert_respond_to @post, :featured_image
  end

  test "should belong to publication" do
    @post.save!
    assert_equal @publication, @post.publication
  end
end