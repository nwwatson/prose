module PostCardsHelper
  # Every display option of a post card, with its default. The collection cache
  # key is built from this same list, so an option added here is automatically
  # part of the key; an option the partial reads but this list lacks would let
  # two different cards share one cache entry.
  POST_CARD_OPTIONS = {
    heading: :h3,
    featured: false,
    show_category: true,
    show_author: true,
    show_subtitle: true,
    show_reading_time: true,
    show_excerpt: false
  }.freeze

  # Renders post cards as a cached collection: one `read_multi` for the whole
  # page instead of one cache read per card. `snippets` maps post id to a search
  # result whose `body_snippet` is shown in place of the excerpt.
  def render_post_cards(posts, snippets: {}, **options)
    options.assert_valid_keys(*POST_CARD_OPTIONS.keys)
    options = POST_CARD_OPTIONS.merge(options)

    render partial: "posts/post", collection: posts, as: :post,
      locals: options.merge(snippets: snippets),
      cached: ->(post) { post_card_cache_key(post, snippets[post.id], options) }
  end

  private

  # The search snippet is in the key so a member's snippet card is never served
  # to a reader who may not see it (PostsController#viewable_snippets drops the
  # snippet for them). The locale is in the key because the card holds
  # translated strings and localized dates.
  def post_card_cache_key(post, snippet, options)
    [ post, post.user&.identity, post.category, snippet&.body_snippet, I18n.locale, *options.values_at(*POST_CARD_OPTIONS.keys) ]
  end
end
