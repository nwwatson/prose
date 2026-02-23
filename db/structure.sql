CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "token" varchar NOT NULL, "ip_address" varchar, "user_agent" varchar, "expires_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_758836b4f0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_sessions_on_user_id" ON "sessions" ("user_id") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_sessions_on_token" ON "sessions" ("token") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "action_text_rich_texts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "body" text, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_action_text_rich_texts_uniqueness" ON "action_text_rich_texts" ("record_type", "record_id", "name") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "categories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "slug" varchar NOT NULL, "description" text, "position" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_categories_on_slug" ON "categories" ("slug") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "tags" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "slug" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_tags_on_slug" ON "tags" ("slug") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "posts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar NOT NULL, "subtitle" varchar, "slug" varchar NOT NULL, "status" integer DEFAULT 0 NOT NULL, "published_at" datetime(6), "scheduled_at" datetime(6), "featured" boolean DEFAULT FALSE NOT NULL, "reading_time_minutes" integer DEFAULT 0, "category_id" integer, "user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "loves_count" integer DEFAULT 0 NOT NULL /*application='Prose'*/, "meta_description" text /*application='Prose'*/, "body_plain" text /*application='Prose'*/, CONSTRAINT "fk_rails_9b1b26f040"
FOREIGN KEY ("category_id")
  REFERENCES "categories" ("id")
, CONSTRAINT "fk_rails_5b5ddfd518"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_posts_on_category_id" ON "posts" ("category_id") /*application='Prose'*/;
CREATE INDEX "index_posts_on_user_id" ON "posts" ("user_id") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_posts_on_slug" ON "posts" ("slug") /*application='Prose'*/;
CREATE INDEX "index_posts_on_status" ON "posts" ("status") /*application='Prose'*/;
CREATE INDEX "index_posts_on_published_at" ON "posts" ("published_at") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "post_tags" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "post_id" integer NOT NULL, "tag_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_fdf74b486b"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
, CONSTRAINT "fk_rails_c9d8c5063e"
FOREIGN KEY ("tag_id")
  REFERENCES "tags" ("id")
);
CREATE INDEX "index_post_tags_on_post_id" ON "post_tags" ("post_id") /*application='Prose'*/;
CREATE INDEX "index_post_tags_on_tag_id" ON "post_tags" ("tag_id") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_post_tags_on_post_id_and_tag_id" ON "post_tags" ("post_id", "tag_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "post_views" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "post_id" integer NOT NULL, "ip_hash" varchar, "user_agent" varchar, "referrer" varchar, "source" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_f2f2d28c2c"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
);
CREATE INDEX "index_post_views_on_post_id" ON "post_views" ("post_id") /*application='Prose'*/;
CREATE INDEX "index_post_views_on_created_at" ON "post_views" ("created_at") /*application='Prose'*/;
CREATE INDEX "index_post_views_on_post_id_and_created_at" ON "post_views" ("post_id", "created_at") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "identities" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "handle" varchar, "settings" json DEFAULT '{}', "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_identities_on_handle" ON "identities" ("handle") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "comments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "post_id" integer NOT NULL, "parent_comment_id" integer, "body" text NOT NULL, "approved" boolean DEFAULT TRUE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "identity_id" integer NOT NULL, CONSTRAINT "fk_rails_2530bf1cd4"
FOREIGN KEY ("identity_id")
  REFERENCES "identities" ("id")
, CONSTRAINT "fk_rails_2fd19c0db7"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
, CONSTRAINT "fk_rails_da28d53ee7"
FOREIGN KEY ("parent_comment_id")
  REFERENCES "comments" ("id")
);
CREATE INDEX "index_comments_on_post_id" ON "comments" ("post_id") /*application='Prose'*/;
CREATE INDEX "index_comments_on_parent_comment_id" ON "comments" ("parent_comment_id") /*application='Prose'*/;
CREATE INDEX "index_comments_on_identity_id" ON "comments" ("identity_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "loves" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "post_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "identity_id" integer NOT NULL, CONSTRAINT "fk_rails_398ba21e55"
FOREIGN KEY ("identity_id")
  REFERENCES "identities" ("id")
, CONSTRAINT "fk_rails_c2ec4c8c1b"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
);
CREATE INDEX "index_loves_on_post_id" ON "loves" ("post_id") /*application='Prose'*/;
CREATE INDEX "index_loves_on_identity_id" ON "loves" ("identity_id") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_loves_on_post_id_and_identity_id" ON "loves" ("post_id", "identity_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar NOT NULL, "password_digest" varchar NOT NULL, "role" integer DEFAULT 1 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "identity_id" integer NOT NULL, CONSTRAINT "fk_rails_2f296ee649"
FOREIGN KEY ("identity_id")
  REFERENCES "identities" ("id")
);
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email") /*application='Prose'*/;
CREATE INDEX "index_users_on_identity_id" ON "users" ("identity_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "site_settings" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "site_name" varchar DEFAULT 'Prose' NOT NULL, "site_description" text DEFAULT '', "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "heading_font" varchar DEFAULT 'Playfair Display' /*application='Prose'*/, "subtitle_font" varchar DEFAULT 'Source Serif 4' /*application='Prose'*/, "body_font" varchar DEFAULT 'Source Serif 4' /*application='Prose'*/, "heading_font_size" decimal(4,2) DEFAULT 2.25 /*application='Prose'*/, "subtitle_font_size" decimal(4,2) DEFAULT 1.25 /*application='Prose'*/, "body_font_size" decimal(4,2) DEFAULT 1.13 /*application='Prose'*/, "claude_api_key" varchar /*application='Prose'*/, "gemini_api_key" varchar /*application='Prose'*/, "ai_model" varchar DEFAULT 'claude-sonnet-4-5-20250929' /*application='Prose'*/, "ai_max_tokens" integer DEFAULT 4096 /*application='Prose'*/, "openai_api_key" varchar /*application='Prose'*/, "image_model" varchar DEFAULT 'imagen-4.0-generate-001' /*application='Prose'*/, "background_color" varchar DEFAULT 'cream' /*application='Prose'*/, "dark_theme" varchar DEFAULT 'midnight' /*application='Prose'*/, "dark_bg_color" varchar DEFAULT '#1a1a2e' /*application='Prose'*/, "dark_text_color" varchar DEFAULT '#e0def4' /*application='Prose'*/, "dark_accent_color" varchar DEFAULT '#7ba4cc' /*application='Prose'*/, "email_provider" varchar DEFAULT 'smtp' /*application='Prose'*/, "sendgrid_api_key" varchar /*application='Prose'*/, "email_accent_color" varchar DEFAULT '#18181b' /*application='Prose'*/, "email_background_color" varchar DEFAULT '#f4f4f5' /*application='Prose'*/, "email_body_text_color" varchar DEFAULT '#3f3f46' /*application='Prose'*/, "email_heading_color" varchar DEFAULT '#18181b' /*application='Prose'*/, "email_font_family" varchar DEFAULT 'system' /*application='Prose'*/, "email_footer_text" text DEFAULT '' /*application='Prose'*/, "email_preheader_text" varchar DEFAULT '' /*application='Prose'*/, "email_social_twitter" varchar /*application='Prose'*/, "email_social_github" varchar /*application='Prose'*/, "email_social_linkedin" varchar /*application='Prose'*/, "email_social_website" varchar /*application='Prose'*/, "email_default_template" varchar DEFAULT 'minimal' /*application='Prose'*/);
CREATE TABLE IF NOT EXISTS "models" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "model_id" varchar NOT NULL, "name" varchar NOT NULL, "provider" varchar NOT NULL, "family" varchar, "model_created_at" datetime(6), "context_window" integer, "max_output_tokens" integer, "knowledge_cutoff" date, "modalities" json DEFAULT '{}', "capabilities" json DEFAULT '[]', "pricing" json DEFAULT '{}', "metadata" json DEFAULT '{}', "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_models_on_provider_and_model_id" ON "models" ("provider", "model_id") /*application='Prose'*/;
CREATE INDEX "index_models_on_provider" ON "models" ("provider") /*application='Prose'*/;
CREATE INDEX "index_models_on_family" ON "models" ("family") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "tool_calls" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "tool_call_id" varchar NOT NULL, "name" varchar NOT NULL, "thought_signature" varchar, "arguments" json DEFAULT '{}', "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "message_id" integer NOT NULL, CONSTRAINT "fk_rails_9c8daee481"
FOREIGN KEY ("message_id")
  REFERENCES "messages" ("id")
);
CREATE UNIQUE INDEX "index_tool_calls_on_tool_call_id" ON "tool_calls" ("tool_call_id") /*application='Prose'*/;
CREATE INDEX "index_tool_calls_on_name" ON "tool_calls" ("name") /*application='Prose'*/;
CREATE INDEX "index_tool_calls_on_message_id" ON "tool_calls" ("message_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "messages" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "role" varchar NOT NULL, "content" text, "content_raw" json, "thinking_text" text, "thinking_signature" text, "thinking_tokens" integer, "input_tokens" integer, "output_tokens" integer, "cached_tokens" integer, "cache_creation_tokens" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "chat_id" integer NOT NULL, "model_id" integer, "tool_call_id" integer, CONSTRAINT "fk_rails_c02b47ad97"
FOREIGN KEY ("model_id")
  REFERENCES "models" ("id")
, CONSTRAINT "fk_rails_0f670de7ba"
FOREIGN KEY ("chat_id")
  REFERENCES "chats" ("id")
, CONSTRAINT "fk_rails_552873cb52"
FOREIGN KEY ("tool_call_id")
  REFERENCES "tool_calls" ("id")
);
CREATE INDEX "index_messages_on_role" ON "messages" ("role") /*application='Prose'*/;
CREATE INDEX "index_messages_on_chat_id" ON "messages" ("chat_id") /*application='Prose'*/;
CREATE INDEX "index_messages_on_model_id" ON "messages" ("model_id") /*application='Prose'*/;
CREATE INDEX "index_messages_on_tool_call_id" ON "messages" ("tool_call_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "chats" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "model_id" integer, "post_id" integer, "user_id" integer, "conversation_type" varchar DEFAULT 'chat' NOT NULL /*application='Prose'*/, CONSTRAINT "fk_rails_b19b85f418"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
, CONSTRAINT "fk_rails_1835d93df1"
FOREIGN KEY ("model_id")
  REFERENCES "models" ("id")
, CONSTRAINT "fk_rails_e555f43151"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_chats_on_model_id" ON "chats" ("model_id") /*application='Prose'*/;
CREATE INDEX "index_chats_on_post_id" ON "chats" ("post_id") /*application='Prose'*/;
CREATE INDEX "index_chats_on_user_id" ON "chats" ("user_id") /*application='Prose'*/;
CREATE INDEX "index_chats_on_post_id_and_user_id_and_conversation_type" ON "chats" ("post_id", "user_id", "conversation_type") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "x_posts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "url" varchar NOT NULL, "embed_html" text, "author_name" varchar, "author_username" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_x_posts_on_url" ON "x_posts" ("url") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "youtube_videos" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "url" varchar NOT NULL, "video_id" varchar NOT NULL, "title" varchar, "author_name" varchar, "thumbnail_url" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_youtube_videos_on_url" ON "youtube_videos" ("url") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "subscribers" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar NOT NULL, "confirmed_at" datetime(6), "auth_token" varchar, "auth_token_sent_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "identity_id" integer NOT NULL, "source_post_id" integer, "unsubscribed_at" datetime(6) /*application='Prose'*/, CONSTRAINT "fk_rails_5fff778d93"
FOREIGN KEY ("identity_id")
  REFERENCES "identities" ("id")
, CONSTRAINT "fk_rails_f1d772a46a"
FOREIGN KEY ("source_post_id")
  REFERENCES "posts" ("id")
);
CREATE UNIQUE INDEX "index_subscribers_on_email" ON "subscribers" ("email") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_subscribers_on_auth_token" ON "subscribers" ("auth_token") /*application='Prose'*/;
CREATE INDEX "index_subscribers_on_identity_id" ON "subscribers" ("identity_id") /*application='Prose'*/;
CREATE INDEX "index_subscribers_on_source_post_id" ON "subscribers" ("source_post_id") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "api_tokens" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "name" varchar NOT NULL, "token_digest" varchar NOT NULL, "token_prefix" varchar NOT NULL, "last_used_at" datetime(6), "last_used_ip" varchar, "revoked_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_f16b5e0447"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_api_tokens_on_user_id" ON "api_tokens" ("user_id") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_api_tokens_on_token_digest" ON "api_tokens" ("token_digest") /*application='Prose'*/;
CREATE VIRTUAL TABLE posts_fts USING fts5(
  title,
  subtitle,
  body_plain,
  content='posts',
  content_rowid='id'
)
/* posts_fts(title,subtitle,body_plain) */;
CREATE TRIGGER posts_fts_insert AFTER INSERT ON posts BEGIN
  INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
  VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
END;
CREATE TRIGGER posts_fts_update AFTER UPDATE ON posts BEGIN
  INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
  VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
  INSERT INTO posts_fts(rowid, title, subtitle, body_plain)
  VALUES (NEW.id, NEW.title, NEW.subtitle, NEW.body_plain);
END;
CREATE TRIGGER posts_fts_delete AFTER DELETE ON posts BEGIN
  INSERT INTO posts_fts(posts_fts, rowid, title, subtitle, body_plain)
  VALUES ('delete', OLD.id, OLD.title, OLD.subtitle, OLD.body_plain);
END;
CREATE TABLE IF NOT EXISTS "newsletters" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar NOT NULL, "status" integer DEFAULT 0 NOT NULL, "sent_at" datetime(6), "scheduled_for" datetime(6), "recipients_count" integer DEFAULT 0, "user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "template" varchar /*application='Prose'*/, "accent_color" varchar /*application='Prose'*/, "preheader_text" varchar /*application='Prose'*/, CONSTRAINT "fk_rails_e6829818c0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_newsletters_on_user_id" ON "newsletters" ("user_id") /*application='Prose'*/;
CREATE INDEX "index_newsletters_on_status" ON "newsletters" ("status") /*application='Prose'*/;
CREATE INDEX "index_newsletters_on_scheduled_for" ON "newsletters" ("scheduled_for") /*application='Prose'*/;
CREATE TABLE IF NOT EXISTS "newsletter_deliveries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "newsletter_id" integer NOT NULL, "subscriber_id" integer NOT NULL, "sent_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "opened_at" datetime(6) /*application='Prose'*/, "clicked_at" datetime(6) /*application='Prose'*/, "bounced_at" datetime(6) /*application='Prose'*/, "open_count" integer DEFAULT 0 /*application='Prose'*/, CONSTRAINT "fk_rails_216f0edfce"
FOREIGN KEY ("newsletter_id")
  REFERENCES "newsletters" ("id")
, CONSTRAINT "fk_rails_0f2fe1dbbe"
FOREIGN KEY ("subscriber_id")
  REFERENCES "subscribers" ("id")
);
CREATE INDEX "index_newsletter_deliveries_on_newsletter_id" ON "newsletter_deliveries" ("newsletter_id") /*application='Prose'*/;
CREATE INDEX "index_newsletter_deliveries_on_subscriber_id" ON "newsletter_deliveries" ("subscriber_id") /*application='Prose'*/;
CREATE UNIQUE INDEX "index_newsletter_deliveries_on_newsletter_id_and_subscriber_id" ON "newsletter_deliveries" ("newsletter_id", "subscriber_id") /*application='Prose'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20260223200006'),
('20260223200005'),
('20260223200004'),
('20260223200003'),
('20260223200002'),
('20260223200001'),
('20260223200000'),
('20260223155833'),
('20260223000003'),
('20260223000002'),
('20260223000001'),
('20260221144107'),
('20260220192258'),
('20260220192218'),
('20260219222045'),
('20260219201804'),
('20260219015524'),
('20260219015523'),
('20260219015522'),
('20260219015521'),
('20260219015520'),
('20260219015519'),
('20260219015518'),
('20260219015517'),
('20260218211848'),
('20260218170100'),
('20260218170000'),
('20260218160100'),
('20260218160000'),
('20260218152710'),
('20260218151505'),
('20260218151433'),
('20260218151432'),
('20260218151032'),
('20260218150338'),
('20260218150337'),
('20260218150336'),
('20260218150331'),
('20260218150324'),
('20260218150323'),
('20260218145818'),
('20260218145802');

