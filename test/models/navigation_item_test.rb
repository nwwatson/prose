require "test_helper"

class NavigationItemTest < ActiveSupport::TestCase
  test "valid with internal path" do
    assert NavigationItem.new(label: "About", url: "/about", location: :header).valid?
  end

  test "accepts root path, query strings and anchors" do
    %w[/ /posts?page=2 /#subscribe].each do |url|
      assert NavigationItem.new(label: "x", url: url, location: :header).valid?, url
    end
  end

  test "accepts http(s) URLs and mailto links" do
    %w[https://github.com/prose http://example.com/a mailto:hello@example.com].each do |url|
      assert NavigationItem.new(label: "x", url: url, location: :footer).valid?, url
    end
  end

  test "rejects script, protocol-relative, bare and blank URLs" do
    [ "javascript:alert(1)", "//evil.example", "about", "data:text/html,hi", "/has space", "" ].each do |url|
      item = NavigationItem.new(label: "x", url: url, location: :header)
      assert_not item.valid?, url
      assert item.errors[:url].any?, url
    end
  end

  test "rejects a URL with a trailing injected line" do
    assert_not NavigationItem.new(label: "x", url: "https://example.com\njavascript:alert(1)", location: :header).valid?
  end

  test "social items require a full http(s) URL" do
    assert_not NavigationItem.new(label: "Me", url: "/about", location: :social).valid?
    assert_not NavigationItem.new(label: "Me", url: "mailto:me@example.com", location: :social).valid?
    assert NavigationItem.new(label: "Me", url: "https://x.com/me", location: :social).valid?
  end

  test "requires a label of at most 50 characters" do
    assert_not NavigationItem.new(label: " ", url: "/", location: :header).valid?
    assert_not NavigationItem.new(label: "a" * 51, url: "/", location: :header).valid?
  end

  test "rejects unknown locations" do
    item = NavigationItem.new(label: "x", url: "/", location: "sidebar")
    assert_not item.valid?
    assert item.errors[:location].any?
  end

  test "strips whitespace from label and url" do
    item = NavigationItem.create!(label: "  Blog  ", url: " /posts ", location: :header)
    assert_equal "Blog", item.label
    assert_equal "/posts", item.url
  end

  test "new items are appended to the end of their location" do
    item = NavigationItem.create!(label: "Contact", url: "/contact", location: :header)
    assert_equal 2, item.position

    footer = NavigationItem.create!(label: "Terms", url: "/terms", location: :footer)
    assert_equal 1, footer.position
  end

  test "changing location appends to the new location" do
    item = navigation_items(:about)
    item.update!(location: :footer)
    assert_equal 1, item.position
  end

  test "ordered sorts by position" do
    assert_equal [ navigation_items(:home), navigation_items(:about) ], NavigationItem.header.ordered.to_a
  end

  test "reposition! rewrites positions to match the given order" do
    NavigationItem.reposition!("header", [ navigation_items(:about).id, navigation_items(:home).id ])
    assert_equal [ navigation_items(:about), navigation_items(:home) ], NavigationItem.header.ordered.to_a
  end

  test "reposition! ignores ids from other locations and keeps omitted items" do
    contact = NavigationItem.create!(label: "Contact", url: "/contact", location: :header)
    NavigationItem.reposition!("header", [ contact.id, navigation_items(:privacy).id ])

    assert_equal [ contact, navigation_items(:home), navigation_items(:about) ], NavigationItem.header.ordered.to_a
    assert_equal 0, navigation_items(:privacy).reload.position
  end

  test "move swaps an item with its neighbour" do
    navigation_items(:about).move(:up)
    assert_equal [ navigation_items(:about), navigation_items(:home) ], NavigationItem.header.ordered.to_a

    navigation_items(:about).reload.move("down")
    assert_equal [ navigation_items(:home), navigation_items(:about) ], NavigationItem.header.ordered.to_a
  end

  test "move is a no-op at the edges" do
    navigation_items(:home).move(:up)
    navigation_items(:about).move(:down)
    assert_equal [ navigation_items(:home), navigation_items(:about) ], NavigationItem.header.ordered.to_a
  end

  test "external? is true for absolute and mailto URLs only" do
    assert navigation_items(:github).external?
    assert NavigationItem.new(url: "mailto:a@b.co").external?
    assert_not navigation_items(:home).external?
  end
end
