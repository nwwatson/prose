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
```

Keep model files under 200 lines — extract behavior into concerns when they grow.

### Controller Pattern
Skinny controllers that delegate to models/services. Controllers handle only HTTP concerns.

### Service Layer
- **Form Objects** for multi-model input (e.g., `Registration`)
- **Service Objects** in `app/services/` for business operations (e.g., `Ai::SystemPrompts`, `Ai::PostContextBuilder`)
- **Query Objects** in `app/queries/` for complex queries (e.g., `PostViewsQuery`, `SubscriberGrowthQuery`, `PostEngagementQuery`)

### Background Jobs
Solid Queue (database-backed). Jobs organized by domain in `app/jobs/`. Recurring tasks configured in `config/recurring.yml`.

### AI Integration
Uses the **RubyLLM** gem for a unified LLM interface across providers (Claude for text, Gemini/OpenAI for images). API keys are stored with Active Record Encryption on `SiteSetting` — key presence enables a feature, `nil` disables it (no separate toggle). The `Ai::Configurable` concern handles provider configuration. AI controllers are nested under `admin/posts/:id/ai/` and streaming responses use Turbo Streams + Solid Cable (`AiResponseJob` broadcasts chunks).

### Post Editor
Uses the `admin_editor` layout. Autosave triggers on a 3-second debounce, serializing `#post_form` FormData. The editor drawer is a tabbed panel (AI + Settings). Settings fields use `form="post_form"` attribute with event listeners on the settings tab container to trigger autosave.

### Key Stimulus Controllers
`autosave`, `editor_drawer`, `tag_select`, `custom_select`, `streaming_markdown`, `ai_image_modal`, `typography_preview`

### Social Embeds
`XPost` and `YouTubeVideo` models with oEmbed fetching, embedded in rich text via ActionText.

### Authentication
- **Admin**: session-based (signed cookie, 14-day expiry)
- **Subscribers**: passwordless magic-link (15-minute token expiry)

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

Docker + Kamal. SQLite databases persisted via volume mount (`prose_storage:/rails/storage`). Solid Queue runs in-process with Puma (`SOLID_QUEUE_IN_PUMA=true`).
