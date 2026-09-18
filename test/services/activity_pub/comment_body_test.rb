require "test_helper"

module ActivityPub
  class CommentBodyTest < ActiveSupport::TestCase
    test "converts paragraphs and line breaks to plain text" do
      body = CommentBody.from_html("<p>First line<br>second line</p><p>Next paragraph</p>")
      assert_equal "First line\nsecond line\n\nNext paragraph", body
    end

    test "strips the leading mention of this site's actor" do
      html = %(<p><span class="h-card"><a href="https://example.com/activitypub/actor" class="u-url mention">@<span>blog</span></a></span> Great post!</p>)
      assert_equal "Great post!", CommentBody.from_html(html)
    end

    test "keeps mentions of other accounts" do
      html = %(<p><span class="h-card"><a href="https://x.example/@bob" class="u-url mention">@<span>bob</span></a></span> agreed</p>)
      assert_equal "@bob agreed", CommentBody.from_html(html)
    end

    test "drops markup and scripts" do
      assert_equal "hi", CommentBody.from_html("<p><script>alert(1)</script><b>hi</b></p>")
    end

    test "truncates to the comment length limit" do
      assert_equal 5000, CommentBody.from_html("<p>#{"a" * 6000}</p>").length
    end
  end
end
