require "test_helper"

class PostsSearchGatingTest < ActionDispatch::IntegrationTest
  SECRET = "zebracadabra"

  setup do
    @post = posts(:published_post)
    # The marker sits past anything seo_description or a teaser could include.
    @post.update!(
      visibility: :members_only,
      meta_description: "Public description",
      content: "<p>#{"filler " * 100}confidential #{SECRET} figures</p>"
    )
  end

  test "anonymous search lists a members-only post without its body snippet" do
    get root_path(q: "confidential")

    assert_gated_result
  end

  test "anonymous search lists a paid post without its body snippet" do
    @post.update!(visibility: :paid_only)

    get root_path(q: "confidential")

    assert_gated_result
  end

  test "paginated turbo frame requests do not leak the snippet" do
    get root_path(q: "confidential", page: 1), headers: { "Turbo-Frame" => "posts_page_1" }

    assert_gated_result
  end

  test "confirmed subscriber sees the snippet of a members-only post" do
    sign_in_subscriber(subscribers(:confirmed))

    get root_path(q: "confidential")

    assert_includes response.body, SECRET
  end

  test "free subscriber does not see the snippet of a paid post" do
    @post.update!(visibility: :paid_only)
    sign_in_subscriber(subscribers(:with_token))

    get root_path(q: "confidential")

    assert_gated_result
  end

  test "paid subscriber sees the snippet of a paid post" do
    @post.update!(visibility: :paid_only)
    sign_in_subscriber(subscribers(:confirmed))

    get root_path(q: "confidential")

    assert_includes response.body, SECRET
  end

  test "staff see the snippet of a paid post" do
    @post.update!(visibility: :paid_only)
    sign_in_as(:admin)

    get root_path(q: "confidential")

    assert_includes response.body, SECRET
  end

  test "a snippet cached for a member is not served to an anonymous reader" do
    with_fragment_caching do
      sign_in_subscriber(subscribers(:confirmed))
      get root_path(q: "confidential")
      assert_includes response.body, SECRET

      reset!
      get root_path(q: "confidential")
      assert_gated_result
    end
  end

  private

  def assert_gated_result
    assert_response :success
    assert_select "h3", text: @post.title
    assert_not_includes response.body, SECRET
  end
end
