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

## Architecture

Refer to `docs/design_guide.md` for comprehensive architectural patterns. Key principles:

### Model Organization
Models use **concerns for behavior composition**. Each concern lives in a directory matching the model name:

```
app/models/user.rb                    # class User includes concerns
app/models/user/named.rb              # module User::Named (concern)
app/models/user/authenticatable.rb    # module User::Authenticatable (concern)
app/models/user/api_tokenable.rb     # module User::ApiTokenable (concern)
app/models/post/discoverable.rb      # module Post::Discoverable (related posts, prev/next)
app/models/site_setting/localization.rb  # module SiteSetting::Localization (i18n)
app/models/identity/handleable.rb    # module Identity::Handleable (handle validation/normalization)
app/models/identity/profileable.rb   # module Identity::Profileable (avatar, bio, social links)
app/models/api_token.rb              # Token generation, digest lookup, revocation
```

Keep model files under 200 lines — extract behavior into concerns when they grow.

### Controller Pattern
Skinny controllers that delegate to models/services. Controllers handle only HTTP concerns.

### Service Layer
- **Form Objects** for multi-model input (e.g., `Registration`)
- **Service Objects** in `app/services/` for business operations (e.g., `Ai::SystemPrompts`, `Ai::PostContextBuilder`, `MarkdownRenderer`, `Mcp::Tools::*`)
- **Query Objects** in `app/queries/` for complex queries (e.g., `PostViewsQuery`, `SubscriberGrowthQuery`, `PostEngagementQuery`)

### Internationalization (i18n)
Site-wide locale configured via `SiteSetting.locale` (default: `"en"`). The `SiteSetting::Localization` concern defines `SUPPORTED_LOCALES` and validates the locale value. `ApplicationController` sets `I18n.locale` from the site setting on every request. All UI strings live in `config/locales/en.yml` and `config/locales/es.yml`. To add a new locale: add the language code to `SUPPORTED_LOCALES` in `app/models/site_setting/localization.rb`, add it to `config.i18n.available_locales` in `config/application.rb`, and create the corresponding YAML file in `config/locales/`.

### Background Jobs
Solid Queue (database-backed). Jobs organized by domain in `app/jobs/`. Recurring tasks configured in `config/recurring.yml`.

### AI Integration
Uses the **RubyLLM** gem for a unified LLM interface across providers (Claude for text, Gemini/OpenAI for images). API keys are stored with Active Record Encryption on `SiteSetting` — key presence enables a feature, `nil` disables it (no separate toggle). The `Ai::Configurable` concern handles provider configuration. AI controllers are nested under `admin/posts/:id/ai/` and streaming responses use Turbo Streams + Solid Cable (`AiResponseJob` broadcasts chunks).

### Post Editor
Uses the `admin_editor` layout. Autosave triggers on a 3-second debounce, serializing `#post_form` FormData. The editor drawer is a tabbed panel (AI + Settings). Settings fields use `form="post_form"` attribute with event listeners on the settings tab container to trigger autosave.

### Key Stimulus Controllers
`autosave`, `editor_drawer`, `tag_select`, `custom_select`, `streaming_markdown`, `ai_image_modal`, `typography_preview`, `markdown_preview`

### Author Profiles
Profile data (bio, avatar, social links) lives on the `Identity` model via `Identity::Profileable` concern. Public author pages at `/authors` (index) and `/authors/:handle` (show) are served by `AuthorsController`. Admin profile editing at `/admin/profile` via `Admin::ProfilesController`. Author names on posts link to their profile pages. Bios support markdown via `MarkdownRenderer`.

### Social Embeds
`XPost` and `YouTubeVideo` models with oEmbed fetching, embedded in rich text via ActionText.

### MCP Server (Model Context Protocol)
Prose exposes an MCP endpoint at `POST /mcp` for AI assistants to manage blog content. See `docs/mcp_setup.md` for the full client setup guide.

**Authentication**: Bearer token via `Authorization` header. Tokens are prefixed with `prose_`, stored as SHA256 digests (never raw), and support instant revocation. The `ApiToken` model handles generation, lookup, and usage tracking (last used time/IP). The `User::ApiTokenable` concern adds `has_many :api_tokens` and a convenience `generate_api_token!` method.

**Controller**: `Mcp::SessionsController` (inherits `ActionController::API`) — a single endpoint that authenticates the token, sets `Current.user`, and delegates to the `MCP::Server` gem for JSON-RPC dispatch. Rate limited at 60 req/min per IP.

**Tool architecture**: 14 tools in `app/services/mcp/tools/`, all inheriting from `MCP::Tool`. Each declares a `description`, `input_schema`, and `call(server_context:, **params)` class method. Tools are registered via `Mcp::ToolRegistry.all`.

```
app/services/mcp/
├── tool_registry.rb          # Central registry of all tool classes
├── post_serializer.rb        # Consistent post JSON serialization
├── markdown_converter.rb     # Markdown → HTML (Commonmarker, GFM)
└── tools/
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
- **Admin**: session-based (signed cookie, 14-day expiry)
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
