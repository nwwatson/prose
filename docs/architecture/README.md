# Architecture Notes

Feature-by-feature notes on how Prose is built. `CLAUDE.md` at the repository root keeps the commands, the Git workflow and the cross-cutting rules whose violation causes a bug; these files hold the detail behind them. `docs/design_guide.md` describes the general patterns (concerns, query objects, service objects) with examples from this codebase.

| File | Covers |
|------|--------|
| [models.md](models.md) | Model and concern file map, `Publishable`, `Prunable`, `SiteSetting.current` caching |
| [controllers.md](controllers.md) | `Admin::EditorResource`, `Admin::CrudResource`, masked secrets, admin pagination, admin partials and helpers |
| [authentication.md](authentication.md) | Admin sessions, passkeys, subscriber magic links, API tokens |
| [i18n.md](i18n.md) | Locale, date/time formatting, translation tests |
| [background-jobs.md](background-jobs.md) | Solid Queue, `recurring.yml`, bulk enqueueing |
| [posts.md](posts.md) | Plain text and search, post cards and pagination, post page, versions, status transitions, revisions, RSS |
| [editor.md](editor.md) | Editor layouts, drawer shell, autosave |
| [pages-and-navigation.md](pages-and-navigation.md) | Static pages, navigation menus, author profiles |
| [seo.md](seo.md) | Head tags, JSON-LD, breadcrumbs |
| [css.md](css.md) | BEM components and theme tokens |
| [javascript.md](javascript.md) | Importmap entry points, Stimulus controllers, `app/javascript/lib` |
| [ai.md](ai.md) | RubyLLM, AI controllers, streaming |
| [analytics.md](analytics.md) | Traffic analytics, `AnalyticsRange` |
| [email.md](email.md) | Segments, email/payment adapters, mailer branding, digests, mailing lists |
| [memberships.md](memberships.md) | Stripe memberships and content gating |
| [comments.md](comments.md) | Comment editing and reply notifications |
| [reading-list.md](reading-list.md) | Bookmarks |
| [social-embeds.md](social-embeds.md) | oEmbed attachments |
| [mcp-and-api.md](mcp-and-api.md) | MCP server and REST API internals |
| [webhooks.md](webhooks.md) | Outbound webhooks, `Outbound::Connection` |
| [activitypub.md](activitypub.md) | Fediverse federation, absolute URLs |
| [export.md](export.md) | Markdown/JSON exports |
