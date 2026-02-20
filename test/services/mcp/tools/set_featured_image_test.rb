require "test_helper"

class Mcp::Tools::SetFeaturedImageTest < ActiveSupport::TestCase
  test "attaches featured image to post" do
    user = users(:admin)
    post = posts(:draft_post)
    data = Base64.encode64("fake image content")

    result = Mcp::Tools::SetFeaturedImage.call(
      server_context: { user: user },
      identifier: post.slug,
      filename: "hero.jpg",
      data: data
    )

    parsed = JSON.parse(result.content.first[:text])
    assert parsed["featured_image_attached"]

    post.reload
    assert post.featured_image.attached?
  end

  test "returns error for missing post" do
    user = users(:admin)
    data = Base64.encode64("fake image")

    result = Mcp::Tools::SetFeaturedImage.call(
      server_context: { user: user },
      identifier: "nonexistent",
      filename: "hero.jpg",
      data: data
    )

    parsed = JSON.parse(result.content.first[:text])
    assert parsed["error"]
  end
end
