# Pages, Navigation & Author Profiles

Custom static pages, the navigation menus and public author pages.

## Custom Static Pages
Pages (`Page` model) provide custom static content at top-level URLs (`/:slug`). The catch-all route **must remain last** in `config/routes.rb` (after admin namespace and health check) to avoid intercepting other routes. Pages use `admin_page_editor` layout (simplified editor without AI/preview). Reserved slugs (admin, posts, feed, etc.) are validated at the model level. Pages are **not** added to the site menu automatically — link them from Navigation (below).

## Navigation Menus
`NavigationItem` (`label`, `url`, `location` enum `header`/`footer`/`social` with `validate: true`, `position`, `open_in_new_tab`) is the single source of the public site's menus — the header nav (`layouts/shared/_header_nav`), footer text links, and footer social icons (`layouts/shared/_footer`). There is no hardcoded "Home" link and no per-page "show in navigation" flag; the `CreateNavigationItems` migration converted the old `pages.show_in_navigation`/`pages.position` columns (since dropped) into header items. URLs must be an internal path starting with a single `/`, an `http(s)` URL, or `mailto:` (social items: `http(s)` only) — this validation is what keeps `javascript:` hrefs out of the layout, so don't loosen it. New items (and items moved to another location) are appended via `before_save`; `NavigationItem.reposition!(location, ids)` rewrites positions for drag-and-drop and `#move(:up/:down)` is the keyboard/no-JS fallback.

`NavigationItem.for_location(location)` is what views call. The first call in a request loads every location with one ordered query and memoizes them, grouped by location, on `Current.navigation_items`; later calls read from that. There is deliberately no `Rails.cache` layer (Solid Cache is on SQLite, so a cache read costs about what this query does) and so nothing to expire; a write is seen from the next request. `NavigationItem::SocialPlatform#social_platform` maps the URL host to a platform (unknown hosts → `:website`, `/@user` paths → `:mastodon`), and `NavigationHelper#social_icon(platform)` renders the matching Simple Icons (CC0) SVG from `NavigationHelper::SOCIAL_ICONS`; `navigation_link(item)` adds `target="_blank" rel="noopener noreferrer"` when `open_in_new_tab`.

Admin UI is `Admin::NavigationItemsController` at `/admin/navigation` (admin role only; linked from the sidebar and Settings): one page with a section per location, inline add forms, and a generic `sortable` Stimulus controller (native HTML5 drag-and-drop within one list, PATCHes `{ location, ids }` to `reorder`, reloads the page if that fails). Up/down arrows hide at list edges via Tailwind `group-first/item`/`group-last/item`, so they stay correct after a drag without a re-render. The JSON export includes `navigation_items`.

## Author Profiles
Profile data (bio, avatar, social links) lives on the `Identity` model via `Identity::Profileable` concern. Public author pages at `/authors` (index) and `/authors/:handle` (show) are served by `AuthorsController`. Admin profile editing at `/admin/profile` via `Admin::ProfilesController`. Author names on posts link to their profile pages. Bios support markdown via `MarkdownRenderer`.

