# REST API Guide for Prose

Prose exposes a versioned JSON REST API at `/api/v1/` alongside its [MCP server](mcp_setup.md), for
integrations that don't speak MCP -- mobile apps, custom frontends, data pipelines, and the like. Both
share the same bearer token system.

## 1. Generate an API Token

1. Sign in to your Prose admin panel
2. Navigate to **System > API Tokens** in the sidebar
3. Enter a name for the token (e.g., "Mobile App") and click **Generate Token**
4. Copy the token immediately -- it will only be shown once
5. The token starts with `prose_` and looks like: `prose_a1b2c3d4e5f6...`

## 2. Authenticate Requests

Send the token as a `Bearer` token in the `Authorization` header:

```bash
curl https://your-prose-instance.com/api/v1/posts \
  -H "Authorization: Bearer prose_YOUR_TOKEN_HERE"
```

Requests without a valid, non-revoked token receive `401 Unauthorized` with `{ "error": "..." }`.
The API is rate limited at 60 requests per minute per client IP.

## 3. Endpoints

All responses are JSON. Content is written as Markdown and returned as rendered HTML
(`content_html`) plus plain text (`content_plain`).

### Posts

| Method | Path | Description |
|--------|------|--------------|
| `GET` | `/api/v1/posts` | List posts. Filters: `status`, `category`, `tag`, `search`. Paginated via `page`/`per_page` (max 50). |
| `GET` | `/api/v1/posts/:slug` | Get a single post by slug or numeric ID, with full content. |
| `POST` | `/api/v1/posts` | Create a draft post. `content` is Markdown. |
| `PATCH` | `/api/v1/posts/:slug` | Update a post. Only provided fields are changed. |
| `DELETE` | `/api/v1/posts/:slug` | Permanently delete a post. |
| `POST` | `/api/v1/posts/:slug/publish` | Publish immediately and notify subscribers. |
| `POST` | `/api/v1/posts/:slug/schedule` | Schedule for future publication. Body: `published_at` (ISO 8601, must be in the future). |
| `POST` | `/api/v1/posts/:slug/unpublish` | Revert a published or scheduled post back to draft. |

List responses paginate with an `X-Total-Count` header and a `Link` header (`rel="next"`/`rel="prev"`),
matching the GitHub API convention.

```bash
curl https://your-prose-instance.com/api/v1/posts \
  -H "Authorization: Bearer prose_YOUR_TOKEN_HERE" \
  -d title="My New Post" \
  -d content="# Hello\n\nThis is **markdown**." \
  -d category="Technology" \
  -d "tags[]=Ruby" -d "tags[]=Rails" \
  -X POST
```

### Categories & Tags

| Method | Path | Description |
|--------|------|--------------|
| `GET` | `/api/v1/categories` | List categories with post counts. |
| `GET` | `/api/v1/tags` | List tags with post counts. |
| `POST` | `/api/v1/tags` | Find or create a tag by `name`. |

### Site

| Method | Path | Description |
|--------|------|--------------|
| `GET` | `/api/v1/site` | Site name/description, categories, tags, and post counts. |

### Assets

| Method | Path | Description |
|--------|------|--------------|
| `POST` | `/api/v1/assets` | Upload a file. Multipart `file`, or `filename`/`data` (base64)/`content_type`. Returns the blob URL. |

## 4. Errors

Errors are returned as `{ "error": "message" }` with an appropriate HTTP status: `401` for
authentication failures, `404` when a record isn't found, `422` for validation failures.
