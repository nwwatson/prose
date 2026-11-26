# Prose Design Guide

The patterns Prose's code follows, with examples taken from this codebase. `CLAUDE.md` lists the project rules; `docs/architecture/` explains each feature. This guide is the "why" behind the shape of the code.

---

## 1. Core Principles

### 1.1 Skinny controllers, rich domain

Controllers handle HTTP: params in, a redirect or render out. Behavior lives in models, concerns, services and query objects, so the admin UI, the REST API, MCP tools and background jobs all trigger the same logic.

Post events are an example. Webhooks, fediverse activity and subscriber emails fire from model callbacks (`Post::Webhookable`, `Post::Federatable`, `Post::Notifiable`), not from `Admin::PostsController`, which is why a post published from the editor, the API, MCP or `PublishScheduledPostsJob` behaves identically.

When several controllers share actions, extract a controller concern rather than a base class: `Admin::CrudResource`, `Admin::EditorResource`, `Admin::SiteSettingsResource`, `Paginatable`, `PaymentGating`.

### 1.2 Composition over inheritance

Models include concerns instead of inheriting behavior:

```ruby
# app/models/user.rb
class User < ApplicationRecord
  include Authenticatable
  include ApiTokenable
  include PasskeyAuthenticatable
  include IdentityBacked

  enum :role, { admin: 0, writer: 1 }
  # ...
end
```

### 1.3 Explicit dependencies

Pass collaborators in rather than reaching for globals. Provider adapters are the clearest case: `EmailService.provider` and `PaymentService.provider` read keys from `SiteSetting` once and inject them into the adapter's constructor, so `PaymentService::Stripe` never reads `SiteSetting` itself and can be built with test keys.

---

## 2. Models

### 2.1 Concerns for behavior composition

A concern used by one model lives in a directory named after it; a concern shared by several lives in `app/models/concerns/`.

```
app/models/
├── post.rb
├── post/
│   ├── revisable.rb        # Post::Revisable
│   ├── status_transitions.rb
│   └── webhookable.rb
└── concerns/
    ├── publishable.rb      # Post, Page, Newsletter
    ├── sluggable.rb        # Post, Page, Category, Tag, MailingList
    └── identity_backed.rb  # User, Subscriber
```

A concern groups one responsibility: its callbacks, scopes and validations go in `included do`, its constants at the top, and a comment says why it exists when that isn't obvious.

```ruby
# app/models/post/revisable.rb
module Post::Revisable
  extend ActiveSupport::Concern

  UPDATE_DELAY = 2.minutes
  REVISED_ATTRIBUTES = %w[title subtitle slug body_plain visibility published_at meta_description].freeze

  included do
    before_save :stamp_revision, if: -> { new_record? || REVISED_ATTRIBUTES.any? { |attr| will_save_change_to_attribute?(attr) } }
  end

  def revised?
    saved_change_to_revised_at?
  end
  # ...
end
```

Extract a concern when a model file passes about 200 lines, or when a feature (versioning, federation, billing) has enough methods to test on its own.

Shared concerns can expose a class macro with options, as `Sluggable` (`slugged_from`) and `Publishable` (`publishes_at`) do, so each model states its configuration in one line.

### 2.2 Identity and roles

`Identity` is the person: name, handle, profile, comments, loves and reading list. `User` (admin staff, password and passkeys) and `Subscriber` (readers, magic links) each `belong_to :identity` through `IdentityBacked`. A single site has no accounts or tenants. Staff roles are the `User` enum `admin`/`writer`; controllers enforce them with `before_action :require_admin` and similar checks in `Authorization`.

### 2.3 Current attributes for request context

`Current` (`app/models/current.rb`) holds request-scoped state: `session`, `user`, `subscriber`, `identity`, plus per-request caches (`site_setting`, `navigation_items`). Use it to memoize a lookup that many views and helpers repeat within one request, rather than adding a `Rails.cache` layer on SQLite.

### 2.4 Value objects

Small immutable concepts get a plain class in `app/models/`: `AnalyticsRange` (a range param resolved to a `since` time) and `Currency` (symbols, names and formatting).

### 2.5 Token logic on the model

Tokens and their lookups live on the model that owns them (`ApiToken.generate_for` / `.find_by_raw_token`, `Subscriber#unsubscribe_token` / `.find_by_unsubscribe_token`), so controllers and mailers never touch digests or message verifiers directly.

---

## 3. Services

`app/services/` holds operations that don't belong to one model. There is no base class; a service is a plain Ruby class, usually with a `.call` class method that delegates to an instance:

```ruby
# app/services/referrer_parser.rb
class ReferrerParser
  def self.call(referrer)
    new(referrer).call
  end

  def initialize(referrer)
    @referrer = referrer
  end

  def call
    # ...
  end
end
```

Group related services in a namespace directory (`Mcp::`, `ActivityPub::`, `Exports::`, `Webhooks::`, `Outbound::`, `Ai::`). When two interfaces need the same behavior, they share one service rather than each implementing it: the REST API and the MCP tools both go through `Mcp::PostWriter`, `Mcp::PostListQuery` and `Mcp::PostSerializer`.

---

## 4. Queries

### 4.1 Scopes

Reusable conditions are scopes on the model (`Subscriber.confirmed`, `Post.live`, `Membership.canceled_since(time)`). Scopes that take a blank argument return the relation unfiltered (`Subscriber.search(term)`), so callers can chain them without conditionals.

### 4.2 Query objects

Aggregations for analytics pages live in `app/queries/` (`PostViewsQuery`, `RevenueQuery`, `SegmentSubscribersQuery`, ...). A query object takes an optional base relation, lives for one request and memoizes values other methods derive from:

```ruby
# app/queries/post_views_query.rb
class PostViewsQuery
  def initialize(relation = PostView.all)
    @relation = relation
  end

  def total_views(since: nil)
    scope = @relation
    scope = scope.since(since) if since
    scope.count
  end
end
```

---

## 5. Background Processing

Jobs live flat in `app/jobs/` and inherit from `ApplicationJob`, which runs each job under the site locale. A job that processes many records rescues per record and reports with `Rails.error.report`, so one bad record can't block the rest:

```ruby
class PublishScheduledPostsJob < ApplicationJob
  def perform
    Post.ready_to_publish.find_each do |post|
      post.publish!
    rescue => e
      Rails.error.report(e, handled: true, context: { post_id: post.id })
    end
  end
end
```

Recurring tasks are in `config/recurring.yml`. Solid Queue loads only the block for the current environment, so shared tasks live under the `default` anchor that each environment merges:

```yaml
default: &default
  publish_scheduled_posts:
    class: PublishScheduledPostsJob
    schedule: every minute

production:
  <<: *default
```

Fan-outs use `ActiveJob.perform_all_later` in batches. See `docs/architecture/background-jobs.md`.

---

## 6. Configuration

Site configuration that admins change lives on the `SiteSetting` singleton, with API keys stored under Active Record Encryption; a present key enables a feature and `nil` disables it. Deployment configuration comes from ENV (`APP_HOST`, `SMTP_FROM`, `WEBAUTHN_ORIGIN`, ...), read in one place per value (`EmailService.from_address`, `AppUrlOptions.call`). Domain constants live on the model or concern that uses them (`Webhook::MAX_CONSECUTIVE_FAILURES`, `ReadingListItem::MAX_ITEMS`).

---

## 7. Testing

Minitest with fixtures from `test/fixtures/*.yml` (for example `users(:admin)`, `users(:writer)`, `api_tokens(:admin_token)`). Shared helpers are in `test/support/`.

```ruby
# test/models/api_token_test.rb
class ApiTokenTest < ActiveSupport::TestCase
  test "generate_for creates a token with prose_ prefix" do
    record, raw_token = ApiToken.generate_for(users(:admin), name: "Test Token")

    assert record.persisted?
    assert raw_token.start_with?("prose_")
    assert_equal Digest::SHA256.hexdigest(raw_token), record.token_digest
  end
end
```

- Model and service tests cover behavior, including the sad paths.
- Integration tests cover each controller action and assert literal paths (`"/posts/#{post.slug}"`) rather than route helpers.
- System tests (`bin/rails test:system`) cover JavaScript behavior such as the editor drawer and passkeys.
- `test/integration/hot_request_paths_test.rb` pins query counts on the hottest pages; update it deliberately.

---

## Quick Reference

| Pattern | Where | Example |
|---------|-------|---------|
| Model concern | `app/models/<model>/` | `Post::Revisable` |
| Shared concern with macro | `app/models/concerns/` | `Sluggable` (`slugged_from`), `Publishable` (`publishes_at`) |
| Controller concern | `app/controllers/concerns/` | `Admin::CrudResource`, `Paginatable` |
| Current attributes | `app/models/current.rb` | `Current.user`, `Current.site_setting` |
| Service object | `app/services/` | `ReferrerParser`, `Mcp::PostWriter` |
| Query object | `app/queries/` | `PostViewsQuery` |
| Value object | `app/models/` | `AnalyticsRange`, `Currency` |
| Provider adapter | `app/services/<feature>_service/` | `EmailService::Smtp`, `PaymentService::Stripe` |
