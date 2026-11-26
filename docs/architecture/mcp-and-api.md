# MCP Server & REST API

Architecture of the two programmatic interfaces. Client-facing references: `docs/mcp_setup.md` and `docs/api_setup.md`.

## MCP Server (Model Context Protocol)
Prose exposes an MCP endpoint at `POST /mcp` for AI assistants to manage blog content. See `docs/mcp_setup.md` for the full client setup guide.

**Authentication**: Bearer token via `Authorization` header. Tokens are prefixed with `prose_`, stored as SHA256 digests (never raw), and support instant revocation. The `ApiToken` model handles generation, lookup, and usage tracking (last used time/IP). `ApiToken#touch_usage!` runs on every authenticated MCP and REST request, so it writes (`update_columns`) only when the IP changed or `last_used_at` is older than `USAGE_TOUCH_INTERVAL` (1 minute); the stored time can lag real use by that much. The `User::ApiTokenable` concern adds `has_many :api_tokens` and a convenience `generate_api_token!` method.

**Controller**: `Mcp::SessionsController` (inherits `ActionController::API`) — one `handle` action routed for `GET`/`POST`/`DELETE /mcp` that authenticates the token, sets `Current.user`, and hands the request to the gem's `MCP::Server::Transports::StreamableHTTPTransport` (built per request with `stateless: true, enable_json_response: true`, returning a Rack triple the action renders). Always go through the transport, never `MCP::Server#handle_json` directly. The transport handles the Streamable HTTP rules that real clients depend on: `202` for notifications, `405` for `GET` (no SSE stream), Accept/Content-Type validation, the `MCP-Protocol-Version` header, and the 2026-07-28 per-request envelope. Claude Desktop reaches it through the `mcp-remote` stdio bridge, since `claude_desktop_config.json` can't send a bearer header to a remote URL. Clients (and tests) must send `Content-Type: application/json` plus `Accept: application/json, text/event-stream`. `wrap_parameters false` keeps Rails from parsing the body so the transport returns its own JSON-RPC parse error, and `MAX_REQUEST_BYTES` (16 MB) raises the transport's 4 MiB default for base64 uploads. DNS-rebinding checks are disabled in favor of Rails `config.hosts`. Rate limited at 60 req/min per IP.

**Tool architecture**: 14 tools in `app/services/mcp/tools/`, all inheriting from `Mcp::Tools::Base` (itself an `MCP::Tool` subclass). Each declares a `description`, `input_schema`, and `call(server_context:, **params)` class method. Tools are registered via `Mcp::ToolRegistry.all`, which excludes `Base`. `Base` provides private class-level helpers shared across tools: `with_post` (wraps `find_post` with a `"Post not found: ..."` error envelope on `ActiveRecord::RecordNotFound`) and `success`/`failure` response envelope builders. The lookups themselves — `find_post` (slug-or-numeric-ID), `find_category`, `find_tag`, `find_or_create_tags`, `decode_upload` (base64 → `[StringIO, content_type]`) — live in `Mcp::ContentLookup` (`app/services/mcp/content_lookup.rb`), included into `Base`'s singleton class and into `Api::V1::BaseController`, so MCP and REST share one implementation. `MCP::Tool.inherited` resets description/schema per subclass and `tool_name` derives from the leaf class name, so the intermediate `Base` class doesn't affect tool names or schemas.

```
app/services/mcp/
├── tool_registry.rb          # Central registry of all tool classes
├── content_lookup.rb         # find_post/find_category/find_tag/find_or_create_tags/decode_upload (MCP + REST)
├── post_serializer.rb        # Consistent post JSON serialization (MCP + REST)
├── post_list_query.rb        # Filters + pagination for list_posts and GET /api/v1/posts
├── post_writer.rb            # Single-save create/update for MCP + REST
├── site_info.rb              # get_site_info / GET /api/v1/site payload
├── category_serializer.rb    # Category JSON (MCP + REST)
├── tag_serializer.rb         # Tag JSON (MCP + REST)
├── asset_uploader.rb         # Blob upload + description (MCP + REST)
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

## REST API
A versioned JSON REST API lives alongside MCP at `/api/v1/` for non-MCP integrations (mobile apps, custom frontends, data pipelines). See `docs/api_setup.md` for the full endpoint reference.

`Api::TokenAuthenticatable` (`app/controllers/concerns/api/token_authenticatable.rb`) is the single bearer-token auth implementation, shared by `Mcp::SessionsController` and `Api::V1::BaseController` — it extracts the token, looks it up via `ApiToken.find_by_raw_token`, sets `Current.user`, and calls `render_unauthorized(message)` on failure; each including controller overrides `render_unauthorized` for its own error envelope shape (JSON-RPC for MCP, `{ error: }` for REST). `Api::V1::BaseController < ActionController::API` also rate limits at 60 req/min (matching MCP — `rate_limit` is declared **before** including `Api::TokenAuthenticatable` in both controllers so unauthenticated requests are throttled too; keep that order), maps `ActiveRecord::RecordNotFound`/`RecordInvalid`/`ActionController::ParameterMissing` to `404`/`422`/`400` JSON errors, and provides a `paginate(scope)` helper (`page`/`per_page`, max 50) that sets `X-Total-Count` and a GitHub-style `Link` header.

Resource controllers (`Api::V1::PostsController`, `CategoriesController`, `TagsController`, `SiteController`, `AssetsController`) and the MCP tools are thin: params in, envelope out. Everything between lives in shared services in `app/services/mcp/`, so the two interfaces return the same data for the same request: `Mcp::PostListQuery` (status/category/tag/search filters plus pagination, returning a `Result(posts, total, page, per_page)`; `page < 1` → 1, `per_page` default 20, max 50), `Mcp::PostWriter.create(user:, attrs:)` / `.update(post:, attrs:)`, `Mcp::SiteInfo.call`, `Mcp::CategorySerializer` / `Mcp::TagSerializer` (`.all(detailed:)`; `detailed: false` is the summary shape inside site info), `Mcp::AssetUploader.call(io:, filename:, content_type:)`, and `Mcp::PostSerializer` (whose `content_plain` is `body_plain`). REST adds pagination headers from the query result; MCP puts `total`/`page`/`per_page` in the body and adds a `markdown` snippet to uploads. There is no REST-specific serializer.

Shared semantics (documented in `docs/api_setup.md` and `docs/mcp_setup.md`): an unknown `category`/`tag` **filter** matches no posts; an unknown `category` on create/update raises `Mcp::PostWriter::UnknownCategory` (REST `422`, MCP failure envelope) and saves nothing; only keys present in `attrs` are written, so passing `category`/`content` blank clears it. `PostWriter` assigns everything and saves **once** inside a transaction (tags are written after the save, in the same transaction), so a published post's edit fires each callback, `post.updated` webhook and fediverse Update once — don't split it back into several `update!` calls. Create always forces `status: :draft`.

