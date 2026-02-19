require "test_helper"

class Ai::PostContextBuilderTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
  end

  test "build includes title" do
    context = Ai::PostContextBuilder.new(@post).build
    assert_includes context, "Title: #{@post.title}"
  end

  test "build includes subtitle when present" do
    @post.subtitle = "A great subtitle"
    context = Ai::PostContextBuilder.new(@post).build
    assert_includes context, "Subtitle: A great subtitle"
  end

  test "build excludes subtitle when blank" do
    @post.subtitle = nil
    context = Ai::PostContextBuilder.new(@post).build
    assert_not_includes context, "Subtitle:"
  end

  test "build includes category when present" do
    context = Ai::PostContextBuilder.new(@post).build
    assert_includes context, "Category: #{@post.category.name}"
  end

  test "build includes tags when present" do
    context = Ai::PostContextBuilder.new(@post).build
    assert_includes context, "Status: #{@post.status}"
  end

  test "build_with_overrides uses provided values" do
    context = Ai::PostContextBuilder.new(@post).build_with_overrides(
      title: "Override Title",
      subtitle: "Override Subtitle"
    )
    assert_includes context, "Title: Override Title"
    assert_includes context, "Subtitle: Override Subtitle"
  end

  test "preserves line breaks between block elements in rich text" do
    @post.content = "<h2>The Core Idea</h2><p>Architecture decisions are hard to reverse.</p><h2>Putting It Into Practice</h2><p>Performance is a feature.</p>"
    @post.save!
    context = Ai::PostContextBuilder.new(@post.reload).build

    assert_includes context, "The Core Idea\n"
    assert_includes context, "Architecture decisions are hard to reverse.\n"
    assert_not_includes context, "IdeaArchitecture"
    assert_not_includes context, "reverse.Putting"
    assert_not_includes context, "PracticePerformance"
  end

  test "truncates very long content" do
    long_content = "a" * 60_000
    context = Ai::PostContextBuilder.new(@post).build_with_overrides(content: long_content)
    assert context.length < 60_000
  end
end
