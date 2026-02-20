# MCP Setup Guide for Prose

This guide explains how to connect Claude Desktop, Claude Code, or any MCP client to your Prose blog.

## 1. Generate an API Token

1. Sign in to your Prose admin panel
2. Navigate to **System > API Tokens** in the sidebar
3. Enter a name for the token (e.g., "Claude Desktop") and click **Generate Token**
4. Copy the token immediately -- it will only be shown once
5. The token starts with `prose_` and looks like: `prose_a1b2c3d4e5f6...`

## 2. Configure Claude Desktop

Add the following to your Claude Desktop configuration file:

**macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows:** `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "prose": {
      "url": "https://your-prose-instance.com/mcp",
      "headers": {
        "Authorization": "Bearer prose_YOUR_TOKEN_HERE"
      }
    }
  }
}
```

Replace `your-prose-instance.com` with your actual Prose domain and `prose_YOUR_TOKEN_HERE` with your API token.

## 3. Configure Claude Code

Claude Code can connect to your Prose MCP server using the `claude mcp add` command.

### Add the server

```bash
claude mcp add prose --transport streamable-http https://your-prose-instance.com/mcp \
  --header "Authorization: Bearer prose_YOUR_TOKEN_HERE"
```

Replace `your-prose-instance.com` with your actual Prose domain and `prose_YOUR_TOKEN_HERE` with your API token.

### Verify the connection

```bash
claude mcp list
```

You should see `prose` listed with a `streamable-http` transport.

### Scope options

By default, `claude mcp add` saves the server to your **user** scope (`~/.claude.json`), making it available in all projects. You can also scope it to a specific project:

```bash
# Project-local (saved to .mcp.json in the current directory)
claude mcp add prose --transport streamable-http https://your-prose-instance.com/mcp \
  --header "Authorization: Bearer prose_YOUR_TOKEN_HERE" \
  --scope project
```

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
- **File uploads:** If behind nginx, you may need to increase `client_max_body_size` for base64 image uploads
- **URLs:** Active Storage URLs use relative paths by default. For external access, configure `default_url_options` in your environment
