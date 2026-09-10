require "test_helper"

class MetaTagsHelperTest < ActionView::TestCase
  include MetaTagsHelper
  # seo_head_tags falls back to SiteHelper#default_og_image_url, and
  # meta_tags_for_post resolves the post image via ImageOptimizationHelper.
  include SiteHelper
  include ImageOptimizationHelper
  # seo_head_tags delegates its json_ld: argument to StructuredDataHelper.
  include StructuredDataHelper

  setup do
    @user = users(:admin)
    @post = posts(:published_post)
    @category = categories(:technology)
  end

  def head_fragment(html)
    Nokogiri::HTML5.fragment(html)
  end

  test "page_title appends the site name" do
    assert_equal "Hello — #{site_name}", page_title("Hello")
    assert_equal site_name, page_title
    assert_equal site_name, page_title("")
  end

  test "seo_head_tags renders each tag exactly once with the given values" do
    doc = head_fragment(seo_head_tags(title: "Title", description: "Desc", url: "https://example.com/x"))

    assert_equal [ "Desc" ], doc.css("meta[name='description']").map { |t| t["content"] }
    assert_equal [ "Title" ], doc.css("meta[property='og:title']").map { |t| t["content"] }
    assert_equal [ "website" ], doc.css("meta[property='og:type']").map { |t| t["content"] }
    assert_equal [ "https://example.com/x" ], doc.css("meta[property='og:url']").map { |t| t["content"] }
    assert_equal [ site_name ], doc.css("meta[property='og:site_name']").map { |t| t["content"] }
    assert_equal [ "Desc" ], doc.css("meta[property='og:description']").map { |t| t["content"] }
    assert_equal [ "Title" ], doc.css("meta[name='twitter:title']").map { |t| t["content"] }
    assert_equal [ "Desc" ], doc.css("meta[name='twitter:description']").map { |t| t["content"] }
    assert_equal [ "https://example.com/x" ], doc.css("link[rel='canonical']").map { |t| t["href"] }
  end

  test "seo_head_tags honors the type argument" do
    doc = head_fragment(seo_head_tags(title: "T", description: "D", url: "/x", type: "article"))

    assert_equal [ "article" ], doc.css("meta[property='og:type']").map { |t| t["content"] }
  end

  test "seo_head_tags uses the given image for both open graph and twitter" do
    doc = head_fragment(seo_head_tags(title: "T", description: "D", url: "/x", image: "https://cdn.example.com/a.png"))

    assert_equal [ "https://cdn.example.com/a.png" ], doc.css("meta[property='og:image']").map { |t| t["content"] }
    assert_equal [ "https://cdn.example.com/a.png" ], doc.css("meta[name='twitter:image']").map { |t| t["content"] }
    assert_equal [ "summary_large_image" ], doc.css("meta[name='twitter:card']").map { |t| t["content"] }
  end

  test "seo_head_tags falls back to a summary card when no image is available" do
    assert_nil default_og_image_url
    doc = head_fragment(seo_head_tags(title: "T", description: "D", url: "/x"))

    assert_empty doc.css("meta[property='og:image']")
    assert_equal [ "summary" ], doc.css("meta[name='twitter:card']").map { |t| t["content"] }
  end

  test "seo_head_tags omits description tags when the description is blank" do
    doc = head_fragment(seo_head_tags(title: "T", description: "", url: "/x"))

    assert_empty doc.css("meta[name='description']")
    assert_empty doc.css("meta[property='og:description']")
    assert_empty doc.css("meta[name='twitter:description']")
  end

  test "seo_head_tags truncates the description meta tag at 160 characters" do
    doc = head_fragment(seo_head_tags(title: "T", description: "a" * 200, url: "/x"))

    assert_equal 160, doc.css("meta[name='description']").first["content"].length
  end

  test "seo_head_tags renders json_ld only when given" do
    with_ld = seo_head_tags(title: "T", description: "D", url: "/x", json_ld: { "@type": "WebSite" })
    assert_includes with_ld, "application/ld+json"
    assert_includes with_ld, "WebSite"

    refute_includes seo_head_tags(title: "T", description: "D", url: "/x"), "application/ld+json"
  end

  test "seo_head_tags renders extra_tags between the open graph and twitter groups" do
    html = seo_head_tags(
      title: "T",
      description: "D",
      url: "/x",
      extra_tags: [ tag.meta(property: "article:tag", content: "Ruby") ]
    )

    assert_operator html.index("og:site_name"), :<, html.index("article:tag")
    assert_operator html.index("article:tag"), :<, html.index("twitter:card")
  end

  test "seo_head_tags escapes html in the title and description" do
    html = seo_head_tags(title: "<script>x</script>", description: "<b>d</b>", url: "/x")

    refute_includes html, "<script>"
    assert_includes html, "&lt;script&gt;"
    assert_equal "<script>x</script>", head_fragment(html).css("meta[property='og:title']").first["content"]
  end

  test "meta_tags_for_post emits article metadata in the expected order" do
    @post.category = @category
    html = meta_tags_for_post(@post)
    doc = head_fragment(html)

    assert_equal [ "article" ], doc.css("meta[property='og:type']").map { |t| t["content"] }
    assert_equal [ @post.title ], doc.css("meta[property='og:title']").map { |t| t["content"] }
    assert_equal [ @post.seo_description ], doc.css("meta[name='description']").map { |t| t["content"] }
    assert_equal [ @post.published_at.iso8601 ], doc.css("meta[property='article:published_time']").map { |t| t["content"] }
    assert_equal @post.tags.map(&:name).sort, doc.css("meta[property='article:tag']").map { |t| t["content"] }.sort
    assert_equal [ post_url(@post, slug: @post.slug) ], doc.css("link[rel='canonical']").map { |t| t["href"] }

    assert_operator html.index("og:site_name"), :<, html.index("article:published_time")
    assert_operator html.index("article:published_time"), :<, html.index("twitter:card")
  end

  test "meta_tags_for_post links article:author to the author page when a handle exists" do
    identity = @post.user.identity
    assert identity.handle.present?
    doc = head_fragment(meta_tags_for_post(@post))

    assert_equal [ author_url(identity, handle: identity.handle) ], doc.css("meta[property='article:author']").map { |t| t["content"] }
  end

  test "meta_tags_for_post falls back to the display name when the author has no handle" do
    @post.user.identity.update_column(:handle, nil)
    @post.user.identity.reload
    doc = head_fragment(meta_tags_for_post(@post))

    assert_equal [ @post.user.display_name ], doc.css("meta[property='article:author']").map { |t| t["content"] }
  end
end
