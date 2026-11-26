require "test_helper"

# The work the busiest requests must not repeat (query and render counts).
class HotRequestPathsTest < ActionDispatch::IntegrationTest
  HEADINGS = "<h2>One</h2><p>a</p><h2>Two</h2><p>b</p><h2>Three</h2><p>c</p>".freeze

  setup do
    @post = posts(:published_post)
    @post.update!(content: HEADINGS)
  end

  test "posts#show renders the Action Text body once without a table of contents" do
    @post.update!(show_toc: false)

    assert_body_rendered_once
    assert_select "[data-controller=toc]", count: 0
  end

  test "posts#show renders the Action Text body once with a table of contents" do
    @post.update!(show_toc: true)

    assert_body_rendered_once
    assert_select "[data-controller=toc] .post-detail__content h2#one"
  end

  test "posts#show renders the Action Text body once with too few headings for a table of contents" do
    @post.update!(show_toc: true, content: "<h2>Only</h2>")

    assert_body_rendered_once
    assert_select "[data-controller=toc]", count: 0
  end

  test "the hero image loads eagerly with high priority" do
    @post.featured_image.attach(io: file_fixture_io, filename: "hero.png", content_type: "image/png")

    get post_path(slug: @post.slug)

    assert_select "img.post-detail__featured-image-img[loading=eager][fetchpriority=high]"
  end

  test "a public page loads navigation with one query and no cache reads" do
    with_fragment_caching do
      reads = []
      recorder = ->(*, payload) { reads << payload[:key].to_s if payload[:key].to_s.include?("navigation") }

      ActiveSupport::Notifications.subscribed(recorder, "cache_read.active_support") do
        assert_query_count(1, table: "navigation_items") { get post_path(slug: @post.slug) }
      end

      assert_response :success
      assert_empty reads
      assert_select "a", text: navigation_items(:about).label
    end
  end

  test "anonymous readers get no comment edit forms" do
    get post_path(slug: @post.slug)

    assert_select "#comment_#{comments(:recent_comment).id}"
    assert_select "form.comment__edit-form", count: 0
  end

  test "only the owner gets an edit form, and only inside the edit window" do
    sign_in_subscriber(subscribers(:confirmed))

    get post_path(slug: @post.slug)

    assert_select "form.comment__edit-form", count: 1
    assert_select "#edit_comment_#{comments(:recent_comment).id} form.comment__edit-form"
  end

  test "a new comment's turbo stream carries the owner's edit form" do
    sign_in_subscriber(subscribers(:confirmed))

    post post_comments_path(@post), params: { comment: { body: "Fresh" } }, as: :turbo_stream

    assert_match "edit_comment_#{Comment.order(:id).last.id}", response.body
    assert_match "comment__edit-form", response.body
  end

  test "a JSON autosave queries no chats and decrypts no API key" do
    configure_ai!
    sign_in_as(:admin)

    decrypts = capture_decrypts do
      assert_query_count(0, table: "chats") { autosave(title: "Autosaved") }
    end

    assert_response :success
    assert_equal 0, decrypts
    assert_equal "Autosaved", @post.reload.title
  end

  test "a failing JSON autosave queries no chats and decrypts no API key" do
    configure_ai!
    sign_in_as(:admin)

    decrypts = capture_decrypts do
      assert_query_count(0, table: "chats") { autosave(title: "") }
    end

    assert_response :unprocessable_entity
    assert_equal 0, decrypts
  end

  test "the editor and a re-rendered HTML update still load the chat" do
    configure_ai!
    sign_in_as(:admin)

    assert_difference "Chat.count", 1 do
      get edit_admin_post_path(@post)
    end
    assert_select "[data-controller~=ai-chat]"

    Chat.delete_all
    assert_difference "Chat.count", 1 do
      patch admin_post_path(@post), params: { post: { title: "" } }
    end
    assert_response :unprocessable_entity
    assert_select "[data-controller~=ai-chat]"
  end

  test "an unconfigured AI request is turned away before RubyLLM is configured" do
    sign_in_as(:admin)
    configured = 0

    with_singleton_stub(::Ai::Client, :configure!, ->(*) { configured += 1 }) do
      get admin_post_ai_conversation_path(@post)
    end

    assert_redirected_to edit_admin_settings_path
    assert_equal 0, configured
  end

  private

  def assert_body_rendered_once
    renders = 0
    counter = ->(*, payload) { renders += 1 if payload[:identifier].to_s.end_with?("action_text/contents/_content.html.erb") }

    ActiveSupport::Notifications.subscribed(counter, /\Arender_\w+\.action_view\z/) do
      get post_path(slug: @post.slug)
    end

    assert_response :success
    assert_equal 1, renders
  end

  def autosave(attributes)
    patch admin_post_path(@post), params: { post: attributes }, headers: { "Accept" => "application/json" }
  end

  def configure_ai!
    SiteSetting.current.update!(claude_api_key: "sk-ant-test")
  end

  def capture_decrypts
    count = 0
    original = ActiveRecord::Encryption::Encryptor.instance_method(:decrypt)
    spy = ->(*args, **options) do
      count += 1
      original.bind_call(self, *args, **options)
    end

    with_instance_stub(ActiveRecord::Encryption::Encryptor, :decrypt, spy) { yield }
    count
  end

  def file_fixture_io
    StringIO.new(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="))
  end
end
