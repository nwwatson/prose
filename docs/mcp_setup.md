# MCP Setup Guide for Prose

This guide explains how to connect Claude Desktop, Claude Code, or any MCP client to your Prose blog.

## 1. Generate an API Token

1. Sign in to your Prose admin panel
2. Navigate to **System > API Tokens** in the sidebar
3. Enter a name for the token (e.g., "Claude Desktop") and click **Generate Token**
4. Copy the token immediately -- it will only be shown once
5. The token starts with `prose_` and looks like: `prose_a1b2c3d4e5f6...`

## 2. Configure Claude Desktop

Prose serves MCP over **Streamable HTTP** and authenticates with a bearer token. Claude Desktop's
`claude_desktop_config.json` only launches local (stdio) servers, and its remote "custom connectors"
(Settings → Connectors) support OAuth rather than a static `Authorization` header. So Claude Desktop
connects through [`mcp-remote`](https://www.npmjs.com/package/mcp-remote), a small local bridge that
Claude Desktop runs as a stdio server and that forwards requests to Prose with your token. It needs
Node.js 18+ (`npx` must be on your `PATH`).

Open **Settings → Developer → Edit Config** in Claude Desktop, or edit the file directly:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "prose": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://your-prose-instance.com/mcp",
        "--header",
        "Authorization:${PROSE_AUTH_HEADER}"
      ],
      "env": {
        "PROSE_AUTH_HEADER": "Bearer prose_YOUR_TOKEN_HERE"
      }
    }
  }
}
```

Replace `your-prose-instance.com` with your actual Prose domain and `prose_YOUR_TOKEN_HERE` with your API
token, then fully quit and reopen Claude Desktop. The Prose tools appear under the tools (🔨) menu.

> The header is written as `Authorization:${PROSE_AUTH_HEADER}` with **no space after the colon**, and
> the `Bearer ` prefix lives in the env var, because Claude Desktop on Windows mangles arguments that
> contain spaces.

**Troubleshooting:** Claude Desktop writes each server's log to `~/Library/Logs/Claude/mcp-server-prose.log`
(macOS) or `%APPDATA%\Claude\logs\mcp-server-prose.log` (Windows). A `401` means the token is wrong or
revoked. If `mcp-remote` then tries to open a browser for OAuth, cancel it and fix the token. Prose
doesn't use OAuth.

## 3. Configure Claude Code

Claude Code speaks Streamable HTTP natively and can connect to Prose directly using the `claude mcp add` command.

### Add the server

```bash
claude mcp add --transport http prose https://your-prose-instance.com/mcp \
  --header "Authorization: Bearer prose_YOUR_TOKEN_HERE"
```

Replace `your-prose-instance.com` with your actual Prose domain and `prose_YOUR_TOKEN_HERE` with your API token.
Options (`--transport`, `--scope`) go before the server name.

### Verify the connection

```bash
claude mcp list
```

You should see `prose` listed as an `HTTP` server with a ✔ connected status.

### Scope options

By default, `claude mcp add` uses the **local** scope: the server is saved in `~/.claude.json` and is available only to you, in the current project. Use `--scope user` to make it available in all your projects, or `--scope project` to share it through a `.mcp.json` file in the project root:

```bash
claude mcp add --transport http --scope user prose https://your-prose-instance.com/mcp \
  --header "Authorization: Bearer prose_YOUR_TOKEN_HERE"
```

A `.mcp.json` file is meant to be committed, so don't put your token in it directly. Reference an
environment variable instead (`"Authorization": "Bearer ${PROSE_TOKEN}"`).

### Remove the server

```bash
claude mcp remove prose
```

## 4. Available Tools

### Post Management

| Tool | Description |
|------|-------------|
| `list_posts` | List posts with filters (status, category, tag, search). Paginated. |
| `get_post` | Get a single post by slug or ID, with full content. |
| `create_post` | Create a new draft post from markdown content. |
| `update_post` | Update any post attributes. Content accepts markdown. |
| `delete_post` | Permanently delete a post. |
| `publish_post` | Publish a post immediately. Triggers subscriber notifications. |
| `schedule_post` | Schedule a post for future publication (ISO 8601 datetime). |
| `unpublish_post` | Revert a post to draft status. |

### Site Information

| Tool | Description |
|------|-------------|
| `get_site_info` | Site name, description, categories, tags, and post counts. |
| `list_categories` | All categories with post counts. |
| `list_tags` | All tags with post counts. |
| `create_tag` | Find or create a tag by name. |

### Assets

| Tool | Description |
|------|-------------|
| `upload_asset` | Upload images/files as base64. Returns URL + markdown snippet. |
| `set_featured_image` | Set a post's featured image from base64 data. |

## 5. Example Workflows

### Create and publish a blog post

```
You: Write a blog post about Ruby 3.4 features and publish it

Claude: I'll create a new post about Ruby 3.4 features.
[Uses create_post with markdown content]
[Uses publish_post to publish it]
```

### Upload an image and include it in a post

```
You: Upload this image and add it to my draft post "my-draft"

Claude: I'll upload the image and update your post.
[Uses upload_asset to upload the image, gets URL back]
[Uses update_post to add the image markdown to the post content]
```

### Check site status

```
You: What's the current state of my blog?

Claude: Let me check your site.
[Uses get_site_info to get overview]
[Uses list_posts to see recent posts]
```

## 6. Content Format

All content is provided as **markdown** and automatically converted to HTML for storage. Supported markdown features:

- Headings (`# H1` through `###### H6`)
- Bold (`**text**`), italic (`*text*`), strikethrough (`~~text~~`)
- Links (`[text](url)`) and images (`![alt](url)`)
- Code blocks with syntax highlighting
- Tables (GFM format)
- Task lists (`- [x] done`, `- [ ] todo`)
- Block quotes, ordered/unordered lists

## 7. Token Management

- Tokens can be revoked at any time from the admin panel
- Revoked tokens immediately lose access
- Each token tracks its last usage time and IP address
- Admin users can see all tokens; writers see only their own

## 8. Production Notes

- **Rate limiting:** The MCP endpoint allows 60 requests per minute per IP
- **Transport:** `/mcp` is a stateless Streamable HTTP endpoint that answers with plain JSON. `POST` carries JSON-RPC messages (notifications are acknowledged with `202 Accepted`), `GET` returns `405` because there is no server-initiated event stream, and `DELETE` is accepted as a no-op. Clients must send `Content-Type: application/json` and an `Accept` header that includes `application/json`
- **Request size:** MCP request bodies are capped at 16 MB (`Mcp::SessionsController::MAX_REQUEST_BYTES`). Base64 inflates files by a third, so uploaded images can be up to roughly 12 MB
- **File uploads:** If behind nginx, you may need to increase `client_max_body_size` for base64 image uploads
- **URLs:** Active Storage URLs use relative paths by default. For external access, configure `default_url_options` in your environment
