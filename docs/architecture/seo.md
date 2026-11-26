# SEO

Head tags, structured data and breadcrumbs.

## SEO Head Tags
`MetaTagsHelper#seo_head_tags(title:, description:, url:, type:, image:, extra_tags:, json_ld:)` emits a page's whole SEO `<head>` sequence — description meta, Open Graph group, `extra_tags`, Twitter card group, canonical link, optional JSON-LD — in that fixed order. Every public page view calls it once instead of chaining `meta_description_tag` / `open_graph_tags` / `twitter_card_tags` / `canonical_tag` / `json_ld_tag`; `meta_tags_for_post` is a thin wrapper that passes the post's `article:*` metadata through `extra_tags` (which is why the slot sits between the OG and Twitter groups). The image is resolved once per call and shared by both the OG and Twitter groups.

The helpers are split by responsibility: `MetaTagsHelper` (page title + meta/OG/Twitter/canonical tags), `StructuredDataHelper` (`json_ld_tag`, `json_ld_for_post`, `json_ld_for_author`, `json_ld_breadcrumb_list`), and `BreadcrumbsHelper` (`breadcrumb_items`, `breadcrumb_navigation`). `breadcrumb_items` returns `{name:, path:, url:}` entries and is the single source for both the visible breadcrumb nav (uses `:path`) and the BreadcrumbList JSON-LD (uses `:url`); the last entry has neither because it is the current page. Rails includes all helpers in views automatically, but helper *tests* must `include` each module they reach into (e.g. `StructuredDataHelperTest` includes `BreadcrumbsHelper` and `ImageOptimizationHelper`).

Image URLs are memoized for the request: `SiteHelper#default_og_image_url` uses a `defined?` guard so a nil result (no OG image configured) isn't recomputed, and `ImageOptimizationHelper#post_og_image_url(post)` caches `optimized_og_image_url` per post id so the head tags and the Article JSON-LD share one variant lookup. `Post#seo_description` and `Page#seo_description` are memoized for the same reason — a page renders them three or four times.

