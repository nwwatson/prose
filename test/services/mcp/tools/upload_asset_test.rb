require "test_helper"

class Mcp::Tools::UploadAssetTest < ActiveSupport::TestCase
  test "uploads base64 file and returns URL" do
    user = users(:admin)
    data = Base64.encode64("fake image content")

    result = Mcp::Tools::UploadAsset.call(
      server_context: { user: user },
      filename: "test.jpg",
      data: data
    )

    parsed = JSON.parse(result.content.first[:text])
    assert parsed["url"].present?
    assert_equal "test.jpg", parsed["filename"]
    assert parsed["markdown"].include?("![test.jpg]")
  end
end
