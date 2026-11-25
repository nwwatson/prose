require "test_helper"

class Mcp::ContentLookupTest < ActiveSupport::TestCase
  class Harness
    include Mcp::ContentLookup
    public(*Mcp::ContentLookup.private_instance_methods)
  end

  setup do
    @lookup = Harness.new
  end

  test "find_post finds by slug" do
    post = posts(:published_post)
    assert_equal post, @lookup.find_post(post.slug)
  end

  test "find_post finds by numeric id, given as integer or string" do
    post = posts(:published_post)
    assert_equal post, @lookup.find_post(post.id)
    assert_equal post, @lookup.find_post(post.id.to_s)
  end

  test "find_post raises RecordNotFound for an unknown slug or id" do
    assert_raises(ActiveRecord::RecordNotFound) { @lookup.find_post("no-such-post") }
    assert_raises(ActiveRecord::RecordNotFound) { @lookup.find_post("999999999") }
  end

  test "find_category matches name first, then slug" do
    assert_equal categories(:technology), @lookup.find_category("Technology")
    assert_equal categories(:technology), @lookup.find_category("technology")
    assert_nil @lookup.find_category("nope")
  end

  test "find_tag matches name first, then slug" do
    assert_equal tags(:ruby), @lookup.find_tag("Ruby")
    assert_equal tags(:ruby), @lookup.find_tag("ruby")
    assert_nil @lookup.find_tag("nope")
  end

  test "find_or_create_tags strips names, drops blanks and reuses existing tags" do
    tags = nil
    assert_difference "Tag.count", 1 do
      tags = @lookup.find_or_create_tags([ " Ruby ", "", nil, "Brand New" ])
    end

    assert_equal [ tags(:ruby), Tag.find_by!(name: "Brand New") ], tags
  end

  test "find_or_create_tags accepts nil" do
    assert_equal [], @lookup.find_or_create_tags(nil)
  end

  test "decode_upload decodes base64 and uses the given content type" do
    io, content_type = @lookup.decode_upload(data: Base64.encode64("hello"), filename: "a.txt", content_type: "text/markdown")

    assert_equal "hello", io.read
    assert_equal "text/markdown", content_type
  end

  test "decode_upload infers the content type from the filename when none is given" do
    _io, content_type = @lookup.decode_upload(data: Base64.encode64("x"), filename: "photo.png", content_type: "")

    assert_equal "image/png", content_type
  end
end
