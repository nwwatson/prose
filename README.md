# Prose

A self-hosted blogging platform built with Ruby on Rails 8.1 and the Solid stack. Prose runs entirely on SQLite — no Redis, Postgres, or external services required.

## Features

- Rich text editing with [Lexxy](https://github.com/basecamp/lexxy)
- Categories and tags for organizing content
- Subscriber management with email notifications
- RSS feed and sitemap generation
- Post scheduling and analytics (views, loves, comments)
- Customizable typography with live preview
- Admin dashboard for managing posts, comments, and subscribers
- SEO-friendly slugged URLs

## Tech Stack

- **Ruby** 3.4.4 / **Rails** 8.1
- **SQLite3** for all persistence
- **Solid Queue** — database-backed background jobs
- **Solid Cache** — database-backed caching
- **Solid Cable** — database-backed WebSockets
- **Hotwire** (Turbo + Stimulus) — SPA-like interactivity
- **Tailwind CSS** — utility-first styling
- **Propshaft** — asset pipeline
- **ImportMap** — JavaScript modules without bundling
- **Kamal** — Docker-based deployment

## Getting Started

### Prerequisites

- Ruby 3.4.4
- SQLite3

### Setup

```bash
bin/setup              # Install dependencies, prepare database, start server
bin/setup --skip-server # Setup without starting the server
```

### Development

```bash
bin/dev                # Start dev server (Puma + Tailwind watcher) on port 3000
```

Visit `http://localhost:3000/admin/setup` to create your admin account.

### Testing

```bash
bin/rails test         # Run all tests
bin/rails test:system  # Run system (browser) tests
```

### Linting and Security

```bash
bin/ci                 # Run full CI locally (setup, lint, security, tests)
bin/rubocop            # Ruby linting
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error  # Security scan
bin/bundler-audit      # Gem vulnerability audit
bin/importmap audit    # JS dependency audit
```

## Contributing

This project uses **GitHub Flow**. The `master` branch is always deployable — all work happens on feature branches and is merged via pull request.

### Workflow

1. Create a branch from `master`:
   ```bash
   git checkout master && git pull
   git checkout -b my-feature-branch
   ```
2. Make your changes and verify they pass all checks:
   ```bash
   bin/rails test         # All unit tests must pass
   bin/rubocop            # All linting must pass
   ```
3. Commit, push, and open a pull request:
   ```bash
   git push -u origin my-feature-branch
   gh pr create
   ```

### PR Requirements

- All unit tests pass (`bin/rails test`)
- No RuboCop offenses (`bin/rubocop`)
- Security scans clean (`bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`)
- One logical change per PR

## Deployment

Prose deploys as a Docker container via [Kamal](https://kamal-deploy.org). SQLite databases are persisted through a volume mount. Solid Queue runs in-process with Puma.

```bash
SOLID_QUEUE_IN_PUMA=true
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
