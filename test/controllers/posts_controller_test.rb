# frozen_string_literal: true

require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @publication = publications(:one)
    @post = posts(:one)
  end

  test "should show post" do
    get publication_post_url(@publication, @post)
    assert_response :success
    assert_select "h1", @post.title
  end

  test "should get new" do
    get new_publication_post_url(@publication)
    assert_response :success
    assert_select "h1", "Create New Post"
  end

  test "should create post with valid params" do
    assert_difference("Post.count") do
      post publication_posts_url(@publication), params: {
        post: {
          title: "New Test Post",
          content: "<p>This is test content</p>",
          summary: "A test summary",
          status: "draft",
          meta_title: "Test Meta Title",
          meta_description: "Test meta description"
        }
      }
    end

    created_post = Post.last
    assert_redirected_to publication_post_url(@publication, created_post)
    assert_equal "New Test Post", created_post.title
    assert_equal "draft", created_post.status
    assert_equal @publication, created_post.publication
  end

  test "should not create post with invalid params" do
    assert_no_difference("Post.count") do
      post publication_posts_url(@publication), params: {
        post: {
          title: "", # Invalid - title is required
          content: "Some content"
        }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".text-red-700", /Title can't be blank/
  end

  test "should get edit" do
    get edit_publication_post_url(@publication, @post)
    assert_response :success
    assert_select "h1", "Edit Post"
  end

  test "should update post with valid params" do
    patch publication_post_url(@publication, @post), params: {
      post: {
        title: "Updated Title",
        summary: "Updated summary",
        status: "published",
        featured: true,
        pinned: false
      }
    }

    assert_redirected_to publication_post_url(@publication, @post)
    @post.reload
    assert_equal "Updated Title", @post.title
    assert_equal "Updated summary", @post.summary
    assert_equal "published", @post.status
    assert @post.featured?
    assert_not @post.pinned?
  end

  test "should not update post with invalid params" do
    patch publication_post_url(@publication, @post), params: {
      post: {
        title: "", # Invalid
        content: "Updated content"
      }
    }
    assert_response :unprocessable_entity
    assert_select ".text-red-700", /Title can't be blank/

    @post.reload
    assert_not_equal "", @post.title
  end

  test "should handle scheduled post creation" do
    scheduled_time = 1.day.from_now

    assert_difference("Post.count") do
      post publication_posts_url(@publication), params: {
        post: {
          title: "Scheduled Post",
          content: "This will be published later",
          status: "scheduled",
          scheduled_at: scheduled_time
        }
      }
    end

    created_post = Post.last
    assert_equal "scheduled", created_post.status
    assert_in_delta scheduled_time.to_i, created_post.scheduled_at.to_i, 1
  end

  test "should publish post" do
    @post.update!(status: "draft")

    patch publish_publication_post_url(@publication, @post)

    assert_redirected_to publication_post_url(@publication, @post)
    @post.reload
    assert @post.published?
    assert_not_nil @post.published_at
  end

  test "should unpublish post" do
    @post.update!(status: "published", published_at: Time.current)

    patch unpublish_publication_post_url(@publication, @post)

    assert_redirected_to publication_post_url(@publication, @post)
    @post.reload
    assert @post.draft?
    assert_nil @post.published_at
  end

  test "should show preview" do
    get preview_publication_post_url(@publication, @post)
    assert_response :success
    assert_select "article"
    assert_select "h1", @post.title
  end

  test "should destroy post" do
    assert_difference("Post.count", -1) do
      delete publication_post_url(@publication, @post)
    end

    assert_redirected_to publication_url(@publication)
  end

  test "should handle featured image upload" do
    image_file = fixture_file_upload("test.png", "image/png")

    assert_difference("Post.count") do
      post publication_posts_url(@publication), params: {
        post: {
          title: "Post with Image",
          content: "Content with featured image",
          featured_image: image_file
        }
      }
    end

    created_post = Post.last
    assert created_post.featured_image.attached?
  end

  test "should handle meta fields" do
    patch publication_post_url(@publication, @post), params: {
      post: {
        meta_title: "Custom Meta Title",
        meta_description: "Custom meta description for SEO"
      }
    }

    @post.reload
    assert_equal "Custom Meta Title", @post.meta_title
    assert_equal "Custom meta description for SEO", @post.meta_description
  end

  test "should handle post status transitions" do
    # Draft to published
    @post.update!(status: "draft")
    patch publication_post_url(@publication, @post), params: {
      post: { status: "published" }
    }
    @post.reload
    assert @post.published?

    # Published to archived
    patch publication_post_url(@publication, @post), params: {
      post: { status: "archived" }
    }
    @post.reload
    assert_equal "archived", @post.status
  end

  test "should require publication parameter" do
    # Test that posts are scoped to the correct publication
    other_publication = Publication.create!(
      name: "Other Publication",
      account: @account
    )
    other_post = other_publication.posts.create!(
      title: "Other Post",
      content: "Content"
    )

    # Should not be able to access post through wrong publication
    assert_raises(ActiveRecord::RecordNotFound) do
      get publication_post_url(@publication, other_post)
    end
  end

  test "should handle featured and pinned flags" do
    patch publication_post_url(@publication, @post), params: {
      post: {
        featured: true,
        pinned: true
      }
    }

    @post.reload
    assert @post.featured?
    assert @post.pinned?
  end

  test "should preserve content during updates" do
    original_content = @post.content.to_s

    patch publication_post_url(@publication, @post), params: {
      post: {
        title: "Updated Title"
      }
    }

    @post.reload
    assert_equal "Updated Title", @post.title
    assert_equal original_content, @post.content.to_s
  end

  test "should show correct breadcrumbs and navigation" do
    get publication_post_url(@publication, @post)
    assert_select "a", @publication.name
    assert_select "span", @post.title
  end

  test "should display post stats in sidebar" do
    @post.update!(view_count: 150, reading_time: 5)

    get publication_post_url(@publication, @post)
    assert_select "span", "150"
    assert_select "span", "5"
  end

  test "should handle empty featured image gracefully" do
    @post.featured_image.purge if @post.featured_image.attached?

    get publication_post_url(@publication, @post)
    assert_response :success
    # Should not have featured image section
    assert_select "img[alt='#{@post.title}']", count: 0
  end
end
