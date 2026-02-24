# Prose

A self-hosted blogging platform built with Ruby on Rails 8.1 and the Solid stack. Prose runs entirely on SQLite — no Redis, Postgres, or external services required.

## Features

- **Writing & Editing** — Rich text with [Lexxy](https://github.com/basecamp/lexxy), autosave, post scheduling, featured posts
- **AI Assistant** — Chat (proofread, critique, brainstorm), SEO/social metadata generation, featured image generation (Gemini/OpenAI), streaming responses
- **MCP Server** — [Model Context Protocol](https://modelcontextprotocol.io) endpoint for managing posts, categories, tags, and assets from Claude Desktop, Claude Code, or any MCP client
- **Content Organization** — Categories, tags with searchable combo box and inline creation
- **Reader Engagement** — Comments with threading and moderation, loves, subscriber magic-link auth, email notifications
- **Social Embeds** — X/Twitter and YouTube via oEmbed
- **Analytics** — Dashboard with view tracking, subscriber growth, post engagement
- **Custom Pages** — Static pages with rich text editor, top-level URLs (e.g. `/about`), optional navigation menu integration
- **Customization** — 30+ Google Fonts, adjustable typography, live preview
- **Internationalization** — Full i18n support with English and Spanish included; site-wide locale setting
- **SEO** — Slugged URLs, meta descriptions, RSS feed, XML sitemap

## Tech Stack

- **Ruby** 3.4.4 / **Rails** 8.1
- **SQLite3** for all persistence
- **Solid Queue** — database-backed background jobs
- **Solid Cache** — database-backed caching
- **Solid Cable** — database-backed WebSockets
- **RubyLLM** — unified AI interface (Claude, Gemini, OpenAI)
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

## MCP Integration

Prose exposes a [Model Context Protocol](https://modelcontextprotocol.io) server at `/mcp`, allowing AI assistants to manage your blog programmatically. See [docs/mcp_setup.md](docs/mcp_setup.md) for the full setup guide.

### Quick Start

1. Generate an API token from **Admin > System > API Tokens**
2. Connect your client:

   **Claude Code:**
   ```bash
   claude mcp add prose --transport streamable-http https://your-domain.com/mcp \
     --header "Authorization: Bearer prose_YOUR_TOKEN"
   ```

   **Claude Desktop** — add to `claude_desktop_config.json`:
   ```json
   {
     "mcpServers": {
       "prose": {
         "url": "https://your-domain.com/mcp",
         "headers": { "Authorization": "Bearer prose_YOUR_TOKEN" }
       }
     }
   }
   ```

### Available Tools

Post management (`list_posts`, `get_post`, `create_post`, `update_post`, `delete_post`, `publish_post`, `schedule_post`, `unpublish_post`), site info (`get_site_info`, `list_categories`, `list_tags`, `create_tag`), and assets (`upload_asset`, `set_featured_image`).

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

Prose deploys as a Docker container via [Kamal](https://kamal-deploy.org). SQLite databases are persisted through a Docker volume mount. Solid Queue runs in-process with Puma.

### Prerequisites

- A VPS or dedicated server with Docker installed (Ubuntu 22.04+ recommended)
- A domain name pointed at your server's IP address
- SSH access to the server as root (or a user with Docker privileges)
- A container registry account (Docker Hub, GitHub Container Registry, etc.) — or use a local registry

Optional:
- SMTP credentials for email delivery (subscriber notifications, magic links)
- S3-compatible storage for file uploads (AWS S3, DigitalOcean Spaces, Cloudflare R2, MinIO)

### Step 1: Configure `config/deploy.yml`

Edit the deployment configuration for your environment:

```yaml
# Set your server IP
servers:
  web:
    - YOUR_SERVER_IP

# Enable SSL with Let's Encrypt (uncomment and set your domain)
proxy:
  ssl: true
  host: yourdomain.com

# Configure your container registry
registry:
  server: ghcr.io          # or hub.docker.com, registry.digitalocean.com
  username: your-username
  password:
    - KAMAL_REGISTRY_PASSWORD

# Set your domain and any optional services
env:
  clear:
    SOLID_QUEUE_IN_PUMA: true
    APP_HOST: yourdomain.com
    # SMTP_ADDRESS: smtp.example.com
    # SMTP_PORT: 587
    # SMTP_USERNAME: your-username
    # SMTP_FROM: noreply@yourdomain.com
    # ACTIVE_STORAGE_SERVICE: amazon
```

### Step 2: Generate Secrets

Generate the required production secrets:

```bash
bin/rails prose:generate_secrets
```

Save the output to `.kamal/.env` (this file is gitignored):

```bash
# .kamal/.env
SECRET_KEY_BASE=<generated value>
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<generated value>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<generated value>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<generated value>
```

Then update `.kamal/secrets` to source them:

```bash
source .kamal/.env
```

> **Warning:** These secrets encrypt your AI API keys and other sensitive data. If lost, encrypted data becomes unrecoverable. Back them up securely. Do not change `SECRET_KEY_BASE` after deployment — it is used for IP anonymization in analytics.

### Step 3: Configure Container Registry

If using GitHub Container Registry:

```bash
# Add to .kamal/.env
KAMAL_REGISTRY_PASSWORD=ghp_your_github_token

# Uncomment in .kamal/secrets
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
```

### Step 4: Deploy

```bash
kamal setup    # First deploy — provisions server, pushes image, starts containers
```

### Step 5: Post-Deployment

1. Visit `https://yourdomain.com/admin/setup` to create your admin account
2. Configure your site name and settings in **Admin > System > Site Settings**
3. Add AI API keys (Anthropic, OpenAI, Google) in site settings to enable AI features

### Optional: Email (SMTP)

Set these environment variables in `config/deploy.yml` under `env.clear` (and `SMTP_PASSWORD` is already in `env.secret`):

```yaml
env:
  clear:
    SMTP_ADDRESS: smtp.example.com
    SMTP_PORT: 587
    SMTP_USERNAME: your-username
    SMTP_FROM: noreply@yourdomain.com
```

### Optional: S3-Compatible Storage

For file uploads stored in S3 instead of local disk:

1. Uncomment `gem "aws-sdk-s3"` in the `Gemfile` and run `bundle install`
2. Set environment variables:

```yaml
env:
  clear:
    ACTIVE_STORAGE_SERVICE: amazon
    AWS_REGION: us-east-1
    AWS_BUCKET: your-bucket-name
    # AWS_ENDPOINT: https://your-endpoint.com  # For S3-compatible services
  secret:
    - AWS_ACCESS_KEY_ID
    - AWS_SECRET_ACCESS_KEY
```

### Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY_BASE` | Yes | — | Rails secret key for sessions and signed cookies |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Yes | — | Encrypts sensitive model attributes (AI API keys) |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | Yes | — | Deterministic encryption for queryable fields |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | Yes | — | Salt for encryption key derivation |
| `APP_HOST` | No | `example.com` | Your domain name (enables host authorization) |
| `RAILS_ASSUME_SSL` | No | `true` | Set to `false` if not using SSL |
| `SOLID_QUEUE_IN_PUMA` | No | `true` | Run background jobs in the web process |
| `ACTIVE_STORAGE_SERVICE` | No | `local` | Storage backend: `local` or `amazon` |
| `SMTP_ADDRESS` | No | — | SMTP server address (enables email delivery) |
| `SMTP_PORT` | No | `587` | SMTP server port |
| `SMTP_USERNAME` | No | — | SMTP authentication username |
| `SMTP_PASSWORD` | No | — | SMTP authentication password |
| `SMTP_FROM` | No | `noreply@example.com` | Default sender email address |
| `SMTP_DOMAIN` | No | `APP_HOST` | HELO domain for SMTP |
| `SMTP_AUTHENTICATION` | No | `plain` | SMTP auth method (`plain`, `login`, `cram_md5`) |
| `WEB_CONCURRENCY` | No | `1` | Number of Puma worker processes |
| `JOB_CONCURRENCY` | No | `1` | Number of Solid Queue worker threads |
| `RAILS_LOG_LEVEL` | No | `info` | Log verbosity (`debug`, `info`, `warn`, `error`) |

### Updating

```bash
kamal deploy   # Build, push, and deploy the latest code
```

### Useful Kamal Commands

```bash
kamal console  # Open Rails console on the server
kamal shell    # Open bash shell in the container
kamal logs     # Tail application logs
kamal details  # Show running containers and health status
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
