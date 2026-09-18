require "test_helper"

class Imports::Ghost::MobiledocRendererTest < ActiveSupport::TestCase
  test "renders markup sections with nested markups and escapes text" do
    html = render(
      markups: [ [ "strong" ], [ "a", [ "href", "https://example.com?a=1&b=2" ] ], [ "script" ] ],
      sections: [
        [ 1, "h3", [ [ 0, [], 0, "Title <x>" ] ] ],
        [ 1, "p", [ [ 0, [ 0 ], 0, "bold " ], [ 0, [ 1 ], 2, "bold link" ], [ 0, [ 2 ], 1, "not script" ] ] ],
        [ 1, "bogus", [ [ 0, [], 0, "fallback" ] ] ]
      ]
    )

    assert_includes html, "<h3>Title &lt;x&gt;</h3>"
    assert_includes html, %(<p><strong>bold <a href="https://example.com?a=1&amp;b=2">bold link</a></strong><span>not script</span></p>)
    assert_includes html, "<p>fallback</p>"
  end

  test "closes markups left open at the end of a section" do
    html = render(markups: [ [ "em" ] ], sections: [ [ 1, "p", [ [ 0, [ 0 ], 0, "open" ] ] ] ])
    assert_equal "<p><em>open</em></p>", html
  end

  test "renders lists, image sections and atoms" do
    html = render(
      atoms: [ [ "soft-return", "↵", {} ] ],
      sections: [
        [ 3, "ol", [ [ [ 0, [], 0, "a" ] ], [ [ 1, [], 0, 0 ] ] ] ],
        [ 2, "https://example.com/i.png" ]
      ]
    )

    assert_includes html, "<ol><li>a</li><li>↵</li></ol>"
    assert_includes html, %(<figure><img src="https://example.com/i.png"></figure>)
  end

  test "renders supported cards" do
    html = render(
      cards: [
        [ "image", { "src" => "https://e.com/a.png", "caption" => "Cap" } ],
        [ "gallery", { "images" => [ { "src" => "https://e.com/1.png" }, { "src" => "https://e.com/2.png" } ] } ],
        [ "markdown", { "markdown" => "**md**" } ],
        [ "html", { "html" => "<div>raw</div>" } ],
        [ "hr", {} ],
        [ "code", { "code" => "a < b" } ],
        [ "embed", { "url" => "https://youtu.be/x" } ],
        [ "bookmark", { "url" => "https://e.com/post", "metadata" => { "title" => "Post" } } ],
        [ "button", { "buttonUrl" => "https://e.com/join", "buttonText" => "Join" } ],
        [ "callout", { "calloutEmoji" => "💡", "calloutText" => "Tip" } ],
        [ "paywall", {} ]
      ],
      sections: (0..10).map { |i| [ 10, i ] }
    )

    assert_includes html, %(<figure><img src="https://e.com/a.png"><figcaption>Cap</figcaption></figure>)
    assert_includes html, %(<img src="https://e.com/1.png"><img src="https://e.com/2.png">)
    assert_includes html, "<strong>md</strong>"
    assert_includes html, "<div>raw</div>"
    assert_includes html, "<hr>"
    assert_includes html, "<pre><code>a &lt; b</code></pre>"
    assert_includes html, %(<a href="https://youtu.be/x">https://youtu.be/x</a>)
    assert_includes html, %(<a href="https://e.com/post">Post</a>)
    assert_includes html, %(<a href="https://e.com/join">Join</a>)
    assert_includes html, "<blockquote><p>💡 Tip</p></blockquote>"
  end

  test "records unsupported cards" do
    renderer = Imports::Ghost::MobiledocRenderer.new(
      "cards" => [ [ "audio", {} ], [ "paywall", {} ] ], "sections" => [ [ 10, 0 ], [ 10, 1 ] ]
    )

    assert_empty renderer.render.strip
    assert_equal [ "audio" ], renderer.unsupported_cards
  end

  test "accepts a JSON string" do
    json = JSON.generate("sections" => [ [ 1, "p", [ [ 0, [], 0, "hi" ] ] ] ])
    assert_equal "<p>hi</p>", Imports::Ghost::MobiledocRenderer.render(json)
  end

  private

  def render(atoms: [], markups: [], cards: [], sections: [])
    Imports::Ghost::MobiledocRenderer.render(
      JSON.parse(JSON.generate("version" => "0.3.1", "atoms" => atoms, "markups" => markups, "cards" => cards, "sections" => sections))
    )
  end
end
