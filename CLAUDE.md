# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Prose is a Ruby on Rails 8.1 application (Ruby 4.0.10) using the "Solid" stack — SQLite3 for all persistence with Solid Queue, Solid Cache, and Solid Cable for jobs, caching, and WebSockets respectively. No external services (Redis, etc.) are required.

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

Feature-by-feature detail lives in [`docs/architecture/`](docs/architecture/README.md) — read the relevant file before changing a feature. [`docs/design_guide.md`](docs/design_guide.md) describes the general patterns. What follows are the conventions and the rules whose violation causes a bug; each section names the file with the full story.

### Code organization
- **Models** compose behavior from concerns in a directory named after the model (`app/models/post/revisable.rb` → `Post::Revisable`); shared concerns live in `app/models/concerns/`. Keep model files under 200 lines. File map: `docs/architecture/models.md`.
- **Controllers** are skinny: HTTP only. Admin controllers reuse `Admin::EditorResource` (post/page/newsletter editors), `Admin::CrudResource` (plain CRUD), `Admin::SiteSettingsResource` and `Admin::OembedEmbeddable`. See `docs/architecture/controllers.md`.
- **Services** in `app/services/` (plain classes with a `.call` or class methods; there is no `ApplicationService` base class), **query objects** in `app/queries/` (one per request, memoize derived values per instance). There are no form objects or interactors.
- **Tests**: Minitest with fixtures; helpers in `test/support/` (see Code Style below).

### Persistence & models
- `publishes_at(column, live_statuses:)` in the `Publishable` concern is the only definition of `live`. `Post` passes `live_statuses: %i[published scheduled]`. There is one `Publishable` module — don't add a `Post::Publishable`, which `include Publishable` in `Post` would silently resolve to.
- "Keep newest N" history goes through `Prunable#prune_to_newest` with a newest-first relation. It deletes in one statement, so pass `destroy: true` when records have callbacks or attachments.
- Children with no callbacks, attachments or dependents use `dependent: :delete_all` (`post_tags`, `post_views`, `post_versions`, `reading_list_items`, `fediverse_likes`, `newsletter_deliveries`, `subscriber_labelings`, `webhook_deliveries`). Giving one of those models a destroy callback, attachment or dependent means switching its parents back to `:destroy`.
- Don't add a single-column index that a composite index on the same table already starts with.
- `SiteSetting.current` is memoized on `Current.site_setting` per request/job (cleared `after_commit`); views call the `site_setting` helper, not `SiteSetting.current`.
- Encrypted keys on `SiteSetting` go in `SiteSetting::MaskedSecrets::SECRET_ATTRIBUTES` and render through `admin/shared/_secret_field` (never a hand-written `password_field`); `assign_attributes_ignoring_mask` keeps the stored key when the mask is submitted.

### Routing & URLs
- **Slug route helpers**: `posts`, `categories` and `tags` use `param: :slug` — call `post_path(slug: post.slug)` or `post_path(post)`, **never both** (`post_url(post, slug: post.slug)` puts the record in `:format` and yields `/posts/my-post.my-post`). Authors use `author_path(handle: identity.handle)`. Nested routes (`post_love_path`, `post_comments_path`) take the record positionally. Tests assert literal paths (`"/posts/#{post.slug}"`), not route helpers.
- The `Page` catch-all route (`/:slug`) **must stay last** in `config/routes.rb`. New top-level public paths need a reserved `Page` slug.
- `AppUrlOptions.call` is the only source of host/protocol for URLs built outside a request; don't read `default_url_options` anywhere else. ActivityPub ids come only from `ActivityPub::Urls`.
- `NavigationItem` URL validation (internal `/path`, `http(s)`, `mailto:`; social items `http(s)` only) is what keeps `javascript:` hrefs out of the layout — don't loosen it. See `docs/architecture/pages-and-navigation.md`.

### Internationalization
Details: `docs/architecture/i18n.md`.
- No user-facing string is hard-coded in a view, controller or JS. `en.yml` and `es.yml` must have identical key sets (`test/models/locale_files_test.rb`), and both carry every Active Model/Active Record default error message (no `rails-i18n` gem). New models/attributes need `activerecord` entries; custom validation messages are symbols defined under `errors.messages`.
- Dates use `l(value, format: ...)`, never `strftime`. `l` dispatches on class: a date-only display of a timestamp column must be `l(value.to_date, format: :short)`, otherwise it silently uses `time.formats`. Relative times use `time_ago`; enum values use `status_label`/`interval_label`, not `capitalize`/`titleize`.
- Mailers and jobs must inherit from `ApplicationMailer`/`ApplicationJob`, which wrap work in `I18n.with_locale(SiteSetting.current.locale)`. `ActionController::API` controllers (REST, MCP, ActivityPub) answer in English.
- Stimulus controllers get their text from `data-*-value` attributes rendered with `t()`, and endpoints as URL values from route helpers.

### Background jobs
Details: `docs/architecture/background-jobs.md`.
- **Solid Queue loads only the `config/recurring.yml` block named after `Rails.env`.** Tasks every environment needs go under `default: &default` (merged into each environment with `<<: *default`); a task added at the top level never runs in production.
- Fan-outs are bulk-enqueued (`ActiveJob.perform_all_later`, `ActionMailer.deliver_all_later`), one call per batch — never one `perform_later` per record. Bulk enqueueing skips enqueue callbacks, so don't add `before_enqueue`/`around_enqueue` to those jobs. Test with `BulkEnqueueHelper#capture_bulk_enqueues`.
- Never hold SQLite's writer lock across an HTTP call: Stripe syncs and similar run from `after_commit` jobs.

### Posts
Details: `docs/architecture/posts.md`.
- `Post#body_plain` is the canonical plain text; never re-derive it from `content.to_plain_text` outside `Post::Searchable#update_body_plain`.
- React to status changes through `Post::StatusTransitions` (`became_published?`, `became_scheduled?`, `left_published?`, `edited_while_published?`), not `saved_change_to_status?`. Creating a post already published behaves like publishing a draft.
- "Updated" webhooks and fediverse Updates are coalesced on `revised_at` (`Post::Revisable`), not `updated_at`.
- Subscriber emails fire from an `after_commit` on the transition to published, claimed through `subscribers_notified_at`. Code creating already-published posts without emails (seeds, imports) must set `subscribers_notified_at`.
- Post cards render only through `render_post_cards`. A new card option goes in `PostCardsHelper::POST_CARD_OPTIONS` (the collection cache key), never as a bare partial local, or two different cards share one cache entry.
- Search snippets quote post text: pass only `PostsController#viewable_snippets` results to a view.
- Gated content: `/feed`, ActivityPub articles and any unauthenticated surface emit the full body only for `visibility_public?` posts; others get `seo_description` plus a link.
- `Mcp::PostWriter` saves once inside a transaction so each edit fires callbacks, webhooks and federation once — don't split it into several `update!` calls.

### Frontend
Details: `docs/architecture/javascript.md`, `docs/architecture/css.md`, `docs/architecture/editor.md`.
- Two importmap entry points: `application` (public) and `admin`. A controller goes in `app/javascript/controllers/` **only if a public view uses it**; admin-only controllers and helpers go in `app/javascript/admin/controllers/` and `app/javascript/admin/lib/`. A public view using an admin controller must move it, or it silently won't connect for readers.
- Use the shared modules in `app/javascript/lib/` instead of re-implementing: `request.js` (CSRF + fetch), `dom.js#escapeHtml` (the only HTML escaper), `clipboard.js`, `timers.js` (timers must be cleared on `disconnect()`), `storage.js` (all `localStorage` access; it throws in private browsing). The `theme` storage key is shared with the inline boot script — don't rename it.
- `tag_select` and `custom_select` bind keydown to `this.element`, not `document`, and `stopPropagation()` on Escape, so the first Escape closes the dropdown and only the next closes the editor drawer. Don't move those listeners to `document`.
- Drawer chrome is changed only in the shared `app/views/layouts/editor/` partials, never in one editor. `Admin::PostsController#load_chat` must not become a `before_action` on `update` (autosave would query chats and decrypt API keys).
- Component CSS is unlayered and beats Tailwind utilities: toggle the `hidden` attribute or a BEM modifier, not the `hidden` class. Use the semantic grey tokens (`muted`, `muted-strong`, `faint`, `rule`, `rule-strong`, `surface`) and existing component classes (`.btn`, `.page-heading`, `.narrow-page`) before adding rules.
- Admin views use the `admin/shared/` partials and `AdminHelper` class helpers (`admin_button_classes`, `admin_input_classes`, `status_badge`, ...) rather than literal class lists; change layout through `size:`/`shape:`/`wrapper_class:`. See `docs/architecture/controllers.md`.
- Never interpolate a secret into JavaScript or use inline `onclick`; `_reveal_secret` copies from the DOM.

### Admin indexes
- Status filters go through `Admin::BaseController#filter_by_status` with a whitelist — never pass a status param to `where`.
- Paginated scopes need a unique tie-breaker (`id`) in their order. A total shown beside a paginated list comes from the unpaginated source. Render `admin/shared/_pagination` outside the empty-state conditional. Test emptiness with `@records.load.any?`.

### Reading list
The bookmark button lives inside the fragment-cached post card, so its markup is **reader-agnostic**: rendered `hidden`, state applied client-side by `bookmark_controller.js` / `lib/reading_list.js`. Never render per-reader state into it. See `docs/architecture/reading-list.md`.

### Email & payments
Details: `docs/architecture/email.md`, `docs/architecture/memberships.md`.
- Provider adapters (`EmailService`, `PaymentService`) get keys injected by their `.provider` factory; adapters never read `SiteSetting`. `deliver_newsletter` must raise when the provider didn't accept the message — `SendNewsletterJob`'s at-least-once bookkeeping depends on it.
- Emailed link tokens live on the models (`Subscriber#unsubscribe_token`, `#email_preferences_token`, `Comment#notification_token`). Their verifier names and 30-day expiry must not change, or links already in inboxes break.
- In mailer templates build post links with `post_url(slug: post.slug)`.
- Email frequency governs post emails only; newsletters ignore it.
- Views check Stripe with the `payments_configured?` helper (`PaymentGating`), not `PaymentService.configured?`.
- Open/click event counters are updated in SQL (`update_all`), never read-modify-write.

### Security
- **Outbound HTTP** to a user- or remote-supplied URL goes only through `Outbound::Connection` (SSRF guard, IP pinning, no redirects, size caps). Don't open a `Net::HTTP` anywhere else. See `docs/architecture/webhooks.md`.
- In `Api::V1::BaseController` and `Mcp::SessionsController`, `rate_limit` is declared **before** `include Api::TokenAuthenticatable` so unauthenticated requests are throttled too. Keep that order.
- MCP requests go through the gem's `StreamableHTTPTransport`, never `MCP::Server#handle_json`. See `docs/architecture/mcp-and-api.md`.
- The JSON export uses the explicit `Exports::JsonExporter::SITE_SETTING_ATTRIBUTES` allowlist; add a column only if it's safe to hand out. Exports download through `Admin::ExportDownloadsController` (never a permanent blob URL). `rubyzip` must stay a direct Gemfile dependency. See `docs/architecture/export.md`.
- Webhooks and exports are admin-only (they can exfiltrate subscriber emails).
- ActivityPub stores no remote HTML (`ActivityPub::CommentBody`), never publishes follower identities, and never rotates the actor keypair automatically. See `docs/architecture/activitypub.md`.
- AI keys are decrypted only on `Admin::Ai::BaseController` requests (`configure_ruby_llm!` after `require_ai_configured`). `RubyLLM::ModelNotFoundError` is not a `RubyLLM::Error` — rescue both. Retiring a model needs a data migration. See `docs/architecture/ai.md`.

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
- **Testing**: Minitest with parallel execution; fixtures loaded from `test/fixtures/*.yml`. Shared helpers live in `test/support/` and are required by `test_helper.rb`: `StubbingHelper` (`with_singleton_stub`, `with_instance_stub`, `with_const`; Minitest 6 dropped `Object#stub`, and these restore exactly what they found, so never stub with a bare `define_method`/`remove_method`), `HttpHelper` (`FakeHTTP`, `with_fake_http`, `stub_oembed_fetch`, `stub_client_chat`), `BulkEnqueueHelper` (include per test class; see Background jobs above), `StripeHelper` (`configure_stripe!`/`unconfigure_stripe!`; the test transaction rolls settings back, so no teardown is needed) and, for integration tests, `ApiHelper` (`ADMIN_API_TOKEN`/`WRITER_API_TOKEN`/`REVOKED_API_TOKEN`, `api_auth_header`, `mcp_headers`, `mcp_call`, `parse_tool_result`). User fixtures hash passwords at `BCrypt::Engine::MIN_COST` to keep sign-ins cheap.
- Composition over inheritance; explicit dependencies over implicit magic

## Deployment

Docker + Kamal. SQLite databases persisted via volume mount (`prose_storage:/rails/storage`). Solid Queue runs in-process with Puma (`SOLID_QUEUE_IN_PUMA=true`). See the README for the full deployment guide.

**No credentials file** — the project does not use `config/credentials.yml.enc` or `config/master.key`. Instead:
- **Development/Test**: hardcoded Active Record Encryption keys in `config/environments/development.rb` and `test.rb`
- **Production**: all secrets come from ENV variables (`SECRET_KEY_BASE`, `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, etc.)
- **Secret generation**: `bin/rails prose:generate_secrets` produces all required production secrets
- **Kamal secrets**: stored in `.kamal/.env` (gitignored), sourced by `.kamal/secrets`
