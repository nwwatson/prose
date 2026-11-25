require "test_helper"

class PostCardsHelperTest < ActionView::TestCase
  include PostCardsHelper

  setup { @post = posts(:published_post) }

  test "every card option changes the cache key" do
    base = post_card_cache_key(@post, nil, POST_CARD_OPTIONS)

    POST_CARD_OPTIONS.each do |name, default|
      changed = POST_CARD_OPTIONS.merge(name => (default == :h3 ? :h2 : !default))
      assert_not_equal base, post_card_cache_key(@post, nil, changed), name
    end
  end

  test "the search snippet and the locale change the cache key" do
    base = post_card_cache_key(@post, nil, POST_CARD_OPTIONS)

    assert_not_equal base, post_card_cache_key(@post, Struct.new(:body_snippet).new("<mark>x</mark>"), POST_CARD_OPTIONS)
    I18n.with_locale(:es) { assert_not_equal base, post_card_cache_key(@post, nil, POST_CARD_OPTIONS) }
  end

  test "rejects an option the cache key does not cover" do
    assert_raises(ArgumentError) { render_post_cards([ @post ], show_love_count: true) }
  end
end
