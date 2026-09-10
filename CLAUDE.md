# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Prose is a Ruby on Rails 8.1 application (Ruby 3.4.4) using the "Solid" stack — SQLite3 for all persistence with Solid Queue, Solid Cache, and Solid Cable for jobs, caching, and WebSockets respectively. No external services (Redis, etc.) are required.

Frontend uses Hotwire (Turbo + Stimulus), Tailwind CSS, Propshaft asset pipeline, and ImportMap for JavaScript modules.

## Common Commands

### Development
```bash
bin/setup              # Full dev environment setup (idempotent), starts server
bin/setup --skip-server # Setup without starting server
bin/setup --reset      # Reset database during setup
bin/dev                # Start dev server (Puma + Tailwind watcher on port 3000)
```

### Testing
```bash
bin/rails test                        # Run all unit tests
bin/rails test test/models/user_test.rb  # Run a single test file
bin/rails test test/models/user_test.rb:15  # Run a single test by line number
bin/rails test:system                 # Run system (browser) tests
bin/rails db:test:prepare             # Prepare test database
```

### CI Pipeline
```bash
bin/ci                 # Run full CI locally (setup, lint, security, tests)
bin/rubocop            # Ruby linting (rubocop-rails-omakase style)
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error  # Security scan
bin/bundler-audit      # Gem vulnerability audit
bin/importmap audit    # JS dependency audit
```

### Database
```bash
bin/rails db:prepare   # Create and migrate database
bin/rails db:migrate   # Run pending migrations
bin/rails db:seed      # Load seed data
bin/rails db:reset     # Drop and recreate from schema
```

The app uses `config.active_record.schema_format = :sql`, so **`db/structure.sql` is the
authoritative schema** — SQL format is required to preserve the FTS5 virtual tables and
triggers that Rails' Ruby schema dumper cannot express. There is no `db/schema.rb`; it is
gitignored, and `db/*_schema.rb` (the generated Solid Queue/Cache/Cable dumps) plus
`db/schema.rb` are excluded from RuboCop in `.rubocop.yml`.

## Architecture

Refer to `docs/design_guide.md` for comprehensive architectural patterns. Key principles:

### Model Organization
Models use **concerns for behavior composition**. Each concern lives in a directory matching the model name:

```
app/models/user.rb                    # class User includes concerns
app/models/user/named.rb              # module User::Named (concern)
app/models/user/authenticatable.rb    # module User::Authenticatable (concern)
app/models/user/api_tokenable.rb     # module User::ApiTokenable (concern)
app/models/user/passkey_authenticatable.rb # module User::PasskeyAuthenticatable (WebAuthn passkeys)
app/models/post/discoverable.rb      # module Post::Discoverable (related posts, prev/next)
app/models/post/versionable.rb      # module Post::Versionable (revision history, version cooldown)
app/models/post_version.rb          # PostVersion: full snapshot of post content per version
app/models/concerns/sluggable.rb     # module Sluggable (slugged_from macro: slug generation/uniquifying, used by Post, Page, Category, Tag)
app/models/comment/editable.rb        # module Comment::Editable (15-min edit window, soft delete)
app/models/comment/notifiable.rb      # module Comment::Notifiable (reply notification callbacks)
app/models/page.rb                    # class Page (custom static pages)
app/models/page/navigable.rb         # module Page::Navigable (navigation menu scope)
app/models/concerns/publishable.rb   # module Publishable — shared `publishes_at` macro (live scope, publish!/schedule!/revert_to_draft!), included by Post, Page, Newsletter
app/validators/future_validator.rb   # FutureValidator: shared "must be in the future" validation used by Publishable
app/models/site_setting/localization.rb  # module SiteSetting::Localization (i18n)
app/models/identity/handleable.rb    # module Identity::Handleable (handle validation/normalization)
app/models/identity/profileable.rb   # module Identity::Profileable (avatar, bio, social links)
app/models/api_token.rb              # Token generation, digest lookup, revocation
app/models/passkey.rb                # WebAuthn passkey credentials for admin sign-in
app/models/subscriber_label.rb       # Labels for subscriber segmentation (name, color)
app/models/subscriber_labeling.rb    # Join model: subscribers ↔ subscriber_labels
app/models/segment.rb                # Saved subscriber filters (JSON filter_criteria)
app/models/segment/resolvable.rb     # module Segment::Resolvable (resolves criteria to subscribers)
app/models/membership_tier.rb       # MembershipTier: paid membership plans (name, price, interval)
app/models/membership_tier/syncable.rb # module MembershipTier::Syncable (syncs to Stripe products/prices)
app/models/membership.rb            # Membership: subscriber ↔ tier link with Stripe subscription state
app/models/subscriber/billable.rb   # module Subscriber::Billable (memberships, paid_member?, stripe_customer_id)
app/models/post/accessible.rb       # module Post::Accessible (visibility enum, content gating)
app/models/site_setting/payment_configuration.rb # module SiteSetting::PaymentConfiguration (Stripe keys)
```

Keep model files under 200 lines — extract behavior into concerns when they grow.

### Controller Pattern
Skinny controllers that delegate to models/services. Controllers handle only HTTP concerns.

`Admin::EditorResource` (`app/controllers/concerns/admin/editor_resource.rb`) is a shared concern for the three editor-backed admin controllers (`Admin::PostsController`, `Admin::PagesController`, `Admin::NewslettersController`). It sets `layout :choose_layout` (editor layout on `new`/`edit`/`create`/`update`, `"admin"` elsewhere — declared per-controller via `uses_editor_layout "admin_editor"` etc.) and provides `respond_with_saved(record, notice:, status:)` / `respond_with_errors(record, template)` for the shared HTML+JSON `respond_to` branches on `create`/`update`. Including controllers implement `resource_json(record)` and `edit_path_for(record)` to supply their resource-specific JSON payload and redirect target; anything else that differs (e.g. `Post#create_version_if_needed!` after update) stays in the controller.

### Service Layer
- **Form Objects** for multi-model input (e.g., `Registration`)
- **Service Objects** in `app/services/` for business operations (e.g., `Ai::SystemPrompts`, `Ai::PostContextBuilder`, `MarkdownRenderer`, `Mcp::Tools::*`)
- **Query Objects** in `app/queries/` for complex queries (e.g., `PostViewsQuery`, `SubscriberGrowthQuery`, `PostEngagementQuery`, `ReferrerAnalyticsQuery`, `SegmentSubscribersQuery`)

### Internationalization (i18n)
Site-wide locale configured via `SiteSetting.locale` (default: `"en"`). The `SiteSetting::Localization` concern defines `SUPPORTED_LOCALES` and validates the locale value. `ApplicationController` sets `I18n.locale` from the site setting on every request. All UI strings live in `config/locales/en.yml` and `config/locales/es.yml`. To add a new locale: add the language code to `SUPPORTED_LOCALES` in `app/models/site_setting/localization.rb`, add it to `config.i18n.available_locales` in `config/application.rb`, and create the corresponding YAML file in `config/locales/`.

### Background Jobs
Solid Queue (database-backed). Jobs organized by domain in `app/jobs/`. Recurring tasks configured in `config/recurring.yml`.

### SiteSetting Caching
`SiteSetting.current` is memoized on `Current.site_setting` (`app/models/current.rb`) for the lifetime of a request or job — `first_or_create!` only runs once per request instead of on every call. An `after_commit` callback on `SiteSetting` clears the memoized value so an update within the same request is not stale. `SiteHelper` exposes a `site_setting` helper method that views should call instead of `SiteSetting.current` directly. `Newsletter::Templatable#resolved_*` methods accept an optional `site` argument so `email_settings` can pass down a single fetched record rather than re-querying per field.

### Admin Settings & Masked Secrets
`Admin::SettingsController` and `Admin::NewsletterSettingsController` share their `edit`/`update` actions via the `Admin::SiteSettingsResource` concern (`app/controllers/concerns/admin/site_settings_resource.rb`); each controller only defines `site_setting_params`, `redirect_path`, and `notice_key`. The `SiteSetting::MaskedSecrets` concern (`app/models/site_setting/masked_secrets.rb`) owns the "••••••••" placeholder mask for encrypted keys (`SECRET_ATTRIBUTES`): `assign_attributes_ignoring_mask(attrs)` drops any secret attribute whose submitted value is still the mask (leaving the stored key unchanged), while a blank value still clears it; `masked_value_for(attribute)` is what views call to render the mask (or "") for a password field's current value.

### AI Integration
Uses the **RubyLLM** gem for a unified LLM interface across providers (Claude for text, Gemini/OpenAI for images). API keys are stored with Active Record Encryption on `SiteSetting` — key presence enables a feature, `nil` disables it (no separate toggle). The `Ai::Configurable` concern handles provider configuration. `configure_ruby_llm!` runs as a `before_action` only on `Admin::Ai::BaseController` (and subclasses) — not on `Admin::BaseController` — so non-AI admin pages don't decrypt AI API keys on every request. AI controllers are nested under `admin/posts/:id/ai/` and streaming responses use Turbo Streams + Solid Cable (`AiResponseJob` broadcasts chunks).

### Custom Static Pages
Pages (`Page` model) provide custom static content at top-level URLs (`/:slug`). The catch-all route **must remain last** in `config/routes.rb` (after admin namespace and health check) to avoid intercepting other routes. Pages use `admin_page_editor` layout (simplified editor without AI/preview). Reserved slugs (admin, posts, feed, etc.) are validated at the model level. Published pages with `show_in_navigation: true` appear in the site header automatically via `Page.navigation` scope.

### Post Editor
Uses the `admin_editor` layout. Autosave triggers on a 3-second debounce, serializing `#post_form` FormData. The editor drawer is a tabbed panel (AI + Settings + Versions). Settings fields use `form="post_form"` attribute with event listeners on the settings tab container to trigger autosave.

### Post Content & Search Indexing
`Post#body_plain` is the canonical plain-text source for a post's content — `Post#excerpt(length)` truncates it and is used by `seo_description`, the featured-post teaser, and the gated-content teaser. Never re-derive plain text from `content.to_plain_text` outside of `Post::Searchable#update_body_plain`; that callback only recomputes `body_plain` when `content` actually changed (`before_save :update_body_plain, if: -> { new_record? || content.changed? }`), so a settings-only save (autosave, love counter, status toggle) skips the Nokogiri parse. `calculate_reading_time` is similarly guarded with `will_save_change_to_body_plain?`. The `posts_fts_update` SQLite trigger has a `WHEN` clause so the FTS5 row is only deleted/reinserted when `title`, `subtitle`, or `body_plain` actually changed. Run `rake posts:backfill_body_plain` to populate `body_plain` for posts created before the column existed.

### Post Versioning
`PostVersion` stores full snapshots (title, subtitle, content HTML, body plain text) on each save. Auto-versioning triggers on update with a 5-minute cooldown (`Post::Versionable`). Manual "Save version" button in the editor drawer's Versions tab. Diff view uses the `diffy` gem for plain-text comparison. "Restore" replaces the post's current content. Max 50 versions per post, pruned inline on version creation. Admin CRUD at `/admin/posts/:id/post_versions`.

### BEM CSS Components
Frontend component styles use BEM (Block Element Modifier) methodology in `app/assets/tailwind/components/`. Each component gets its own file (e.g., `_post-card.css`) imported via the `_index.css` manifest. Theme variables (fonts, colors) are defined in the `@theme` block of `application.css` — Tailwind v4's `@theme` directive cannot be extracted to a separate file. `SiteHelper` methods inject runtime overrides for admin-configurable fonts and colors.

### Key Stimulus Controllers
`autosave`, `editor_drawer`, `tag_select`, `custom_select`, `streaming_markdown`, `ai_image_modal`, `typography_preview`, `markdown_preview`, `traffic_chart`, `segment_builder`, `comment_edit`

### Shared JS Modules
`app/javascript/lib/` holds framework-agnostic helpers shared across Stimulus controllers (pinned via `pin_all_from "app/javascript/lib", under: "lib"` in `config/importmap.rb`, imported as `lib/<name>`).

`lib/request.js` centralizes the CSRF-token meta lookup and the three fetch idioms used throughout the app: `request(url, opts)` (sets `X-CSRF-Token`, JSON-encodes a plain object body, form-encodes a `URLSearchParams` body, passes `FormData` through untouched), `requestJSON(url, opts)` (parses the JSON response and throws with `data.error` when the response isn't ok), and `requestTurboStream(url, opts)` (sets the Turbo Stream `Accept` header and renders the response via `Turbo.renderStreamMessage`). Controllers that POST or fetch should use these helpers instead of duplicating the CSRF meta-tag lookup.

`lib/svg_chart.js` is the shared renderer for all hand-rolled SVG charts (no external charting library) — `svgEl(name, attrs, text)` builds namespaced SVG elements, `renderBarChart(container, entries, opts)` draws gridlines/bars/x-labels for `growth_chart` and `traffic_chart` (which differ only in `minBarWidth`, `labelInterval`, and label formatter — `formatMonthLabel`/`formatDayLabel`), and `renderSparkline(container, values, opts)` draws the dashboard's line+area sparkline (`chart_controller`). All three controllers render into a persistent container element via `container.replaceChildren(...)`, so redrawing (e.g. on data change) doesn't destroy the target. The growth chart's Monthly/Cumulative toggle uses Stimulus `static classes` (`data-growth-chart-active-class` / `-inactive-class`) with `classList.add/remove` rather than string replacement on `className`.

### Author Profiles
Profile data (bio, avatar, social links) lives on the `Identity` model via `Identity::Profileable` concern. Public author pages at `/authors` (index) and `/authors/:handle` (show) are served by `AuthorsController`. Admin profile editing at `/admin/profile` via `Admin::ProfilesController`. Author names on posts link to their profile pages. Bios support markdown via `MarkdownRenderer`.

### Traffic Analytics
`Admin::TrafficController` provides a dedicated deep-dive traffic page at `/admin/traffic` with referrer domain breakdown, UTM campaign/source/medium tables, and a configurable range selector (7d/30d/90d/all). `PostView` stores `referrer_domain`, `utm_source`, `utm_medium`, and `utm_campaign` extracted at write time by `TrackPostViewJob`. `ReferrerAnalyticsQuery` provides aggregation methods. Use `rake referrer:backfill` to populate columns from existing referrer URLs.

### Subscriber Segmentation
`SubscriberLabel` provides tagging for subscribers (name + hex color). `SubscriberLabeling` is the many-to-many join. `Segment` stores saved filter criteria as JSON (`filter_criteria` column) with a `Segment::Resolvable` concern that delegates to `SegmentSubscribersQuery`. Filters support: label matching (any_of/all_of/none_of), date ranges on `confirmed_at`, and engagement level (active/inactive derived from `newsletter_deliveries`). Newsletters have an optional `segment_id` — `Newsletter::Sendable#target_subscribers` returns the segment's resolved subscribers or all confirmed subscribers. Admin CRUD at `/admin/subscriber_labels`, `/admin/segments`. Labels are managed per-subscriber at `/admin/subscribers/:id`.

### Paid Memberships (Stripe)
Prose supports Ghost-style paid memberships with Stripe integration. Feature is gated — UI only appears when Stripe keys are configured in `SiteSetting`. Direct Stripe API keys (not Stripe Connect), stored encrypted like AI keys. 3-level post visibility: `public` (default), `members_only` (free sign-in), `paid_only` (subscription required). `PaymentService` module follows the same provider pattern as `EmailService`. `PaymentService::Stripe` handles checkout sessions, billing portal, subscriptions, and webhook event construction. `StripeWebhookJob` processes checkout completions, subscription updates/deletions, and payment failures (idempotent). `SyncStripeSubscriptionJob` runs daily to keep membership status in sync. Admin controllers at `/admin/payment_settings`, `/admin/membership_tiers`, `/admin/memberships`, `/admin/revenue`. Public pricing page at `/memberships`. Content gating in `posts/show` — `PostsController` sets `@can_view` via `MembershipAccess` concern. Query objects: `RevenueQuery` (MRR, ARR, churn) and `MembershipGrowthQuery` (new/canceled/net by month).

### Comment Features
Comments belong to `Identity` (not `Subscriber`), allowing both admins and subscribers to comment. One-level threading only. Features:
- **Edit/Delete**: Authors can edit within 15 minutes (`Comment::Editable`). Soft delete sets `deleted_at` and replaces body with "[deleted]". Admin hard-delete unchanged.
- **Reply Notifications**: Opt-in via `notify_on_reply` checkbox. `Comment::Notifiable` fires `CommentReplyNotificationJob` on reply creation. `CommentMailer#reply_notification` sends email with token-based unsubscribe (`CommentNotificationsController`).

### Social Embeds
`XPost` and `YouTubeVideo` models with oEmbed fetching, embedded in rich text via ActionText.

### MCP Server (Model Context Protocol)
Prose exposes an MCP endpoint at `POST /mcp` for AI assistants to manage blog content. See `docs/mcp_setup.md` for the full client setup guide.

**Authentication**: Bearer token via `Authorization` header. Tokens are prefixed with `prose_`, stored as SHA256 digests (never raw), and support instant revocation. The `ApiToken` model handles generation, lookup, and usage tracking (last used time/IP). The `User::ApiTokenable` concern adds `has_many :api_tokens` and a convenience `generate_api_token!` method.

**Controller**: `Mcp::SessionsController` (inherits `ActionController::API`) — a single endpoint that authenticates the token, sets `Current.user`, and delegates to the `MCP::Server` gem for JSON-RPC dispatch. Rate limited at 60 req/min per IP.

**Tool architecture**: 14 tools in `app/services/mcp/tools/`, all inheriting from `Mcp::Tools::Base` (itself an `MCP::Tool` subclass). Each declares a `description`, `input_schema`, and `call(server_context:, **params)` class method. Tools are registered via `Mcp::ToolRegistry.all`, which excludes `Base`. `Base` provides private class-level helpers shared across tools: `find_post`/`with_post` (slug-or-numeric-ID lookup with a `"Post not found: ..."` error envelope on `ActiveRecord::RecordNotFound`), `find_category`, `find_or_create_tags`, `decode_upload` (base64 → `[StringIO, content_type]`), and `success`/`failure` response envelope builders. `MCP::Tool.inherited` resets description/schema per subclass and `tool_name` derives from the leaf class name, so the intermediate `Base` class doesn't affect tool names or schemas.

```
app/services/mcp/
├── tool_registry.rb          # Central registry of all tool classes
├── post_serializer.rb        # Consistent post JSON serialization
├── markdown_converter.rb     # Markdown → HTML (Commonmarker, GFM)
└── tools/
    ├── base.rb                # Mcp::Tools::Base — shared post/category/tag/upload helpers, response envelopes
    ├── list_posts.rb          # Filter by status/category/tag/search, paginated
    ├── get_post.rb            # Full post by slug or ID
    ├── create_post.rb         # New draft from markdown
    ├── update_post.rb         # Partial updates
    ├── delete_post.rb         # Permanent deletion
    ├── publish_post.rb        # Immediate publish + subscriber notifications
    ├── schedule_post.rb       # Future publication (ISO 8601)
    ├── unpublish_post.rb      # Revert to draft
    ├── get_site_info.rb       # Site metadata + counts
    ├── list_categories.rb     # Categories with post counts
    ├── list_tags.rb           # Tags with post counts
    ├── create_tag.rb          # Find or create tag
    ├── upload_asset.rb        # Base64 file → ActiveStorage blob
    └── set_featured_image.rb  # Attach featured image to post
```

**Admin UI**: `Admin::ApiTokensController` with token CRUD at `/admin/api_tokens`. Admins see all tokens; writers see only their own. Raw token shown once via flash on creation.

### Authentication
- **Admin**: session-based (signed cookie, 14-day expiry). The `Authentication` concern owns cookie → `Session` resumption (`resume_session`, memoized via a `Current.session` short-circuit) and is included once on `ApplicationController`, so both admin (`current_user`) and identity (`IdentityAuthentication#current_identity`) lookups share a single `sessions` query per request.
- **Admin Passkeys**: optional WebAuthn/passkey sign-in alongside password. Configured via `WEBAUTHN_ORIGIN` and `WEBAUTHN_RP_ID` env vars. Managed at `/admin/passkeys`.
- **Subscribers**: passwordless magic-link (15-minute token expiry)
- **MCP/API**: Bearer token (`prose_`-prefixed, SHA256 digest stored)

## Git Workflow

This project follows **GitHub Flow** (Feature Branch Workflow). All development happens on feature branches created from `master`. The `master` branch is always deployable.

### Rules

1. **Never commit directly to `master`.** Always create a feature branch.
2. **Branch from `master`** for every change — features, bug fixes, docs, refactors.
3. **Name branches descriptively**: `fix-typography-preview`, `add-subscriber-export`, `update-tailwind-config`.
4. **Before opening a pull request**, ensure:
   - All unit tests pass: `bin/rails test`
   - Linting passes with no offenses: `bin/rubocop`
   - Security scans are clean: `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
5. **Submit a pull request** to merge back into `master`. PRs require review before merging.
6. **Keep PRs focused.** One logical change per PR — don't bundle unrelated work.

### Typical Workflow

```bash
git checkout master && git pull
git checkout -b my-feature-branch
# ... make changes ...
bin/rails test && bin/rubocop        # Verify before committing
git add <files> && git commit
git push -u origin my-feature-branch
gh pr create                          # Open pull request against master
```

## Code Style

- **Linter**: RuboCop with `rubocop-rails-omakase` preset (`.rubocop.yml`)
- **Testing**: Minitest with parallel execution; fixtures loaded from `test/fixtures/*.yml`
- Composition over inheritance; explicit dependencies over implicit magic

## Deployment

Docker + Kamal. SQLite databases persisted via volume mount (`prose_storage:/rails/storage`). Solid Queue runs in-process with Puma (`SOLID_QUEUE_IN_PUMA=true`). See the README for the full deployment guide.

**No credentials file** — the project does not use `config/credentials.yml.enc` or `config/master.key`. Instead:
- **Development/Test**: hardcoded Active Record Encryption keys in `config/environments/development.rb` and `test.rb`
- **Production**: all secrets come from ENV variables (`SECRET_KEY_BASE`, `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, etc.)
- **Secret generation**: `bin/rails prose:generate_secrets` produces all required production secrets
- **Kamal secrets**: stored in `.kamal/.env` (gitignored), sourced by `.kamal/secrets`
