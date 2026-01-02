# Prose Data Model Design

## Overview

This document outlines the database schema additions needed to support all planned features for Prose, a personal newsletter and publishing platform.

**Note:** All new tables use standard auto-incrementing integer primary keys (bigint) for simplicity and performance. References to existing authentication tables (accounts, identities, users) use `bigint` foreign key columns to reference the UUID primary keys.

## Existing Authentication Tables

The following tables are already implemented using UUID primary keys for the authentication system:

### Accounts
```ruby
create_table "accounts", id: :uuid, force: :cascade do |t|
  t.datetime "created_at", null: false
  t.string "name"
  t.datetime "updated_at", null: false
end
```

### Identities
```ruby
create_table "identities", id: :uuid, force: :cascade do |t|
  t.datetime "created_at", null: false
  t.string "email_address"
  t.boolean "staff"
  t.datetime "updated_at", null: false
end
```

### Users
```ruby
create_table "users", id: :uuid, force: :cascade do |t|
  t.uuid "account_id", null: false
  t.boolean "active"
  t.datetime "created_at", null: false
  t.uuid "identity_id", null: false
  t.string "name"
  t.string "role"
  t.datetime "updated_at", null: false
  t.datetime "verified_at"
  t.index ["account_id"], name: "index_users_on_account_id"
  t.index ["identity_id"], name: "index_users_on_identity_id"
end
```

### Sessions
```ruby
create_table "sessions", id: :uuid, force: :cascade do |t|
  t.datetime "created_at", null: false
  t.uuid "identity_id", null: false
  t.string "ip_address"
  t.datetime "updated_at", null: false
  t.string "user_agent"
  t.index ["identity_id"], name: "index_sessions_on_identity_id"
end
```

### Magic Links
```ruby
create_table "magic_links", id: :uuid, force: :cascade do |t|
  t.string "code"
  t.datetime "created_at", null: false
  t.datetime "expires_at"
  t.uuid "identity_id", null: false
  t.string "purpose"
  t.datetime "updated_at", null: false
  t.index ["identity_id"], name: "index_magic_links_on_identity_id"
end
```

### Identity Access Tokens
```ruby
create_table "identity_access_tokens", id: :uuid, force: :cascade do |t|
  t.datetime "created_at", null: false
  t.string "description"
  t.uuid "identity_id", null: false
  t.string "permission"
  t.string "token"
  t.datetime "updated_at", null: false
  t.index ["identity_id"], name: "index_identity_access_tokens_on_identity_id"
end
```

---

## Phase 1: Core Publishing Foundation

### Publications
The top-level container for a newsletter/publication within an account.

```ruby
# db/migrate/xxx_create_publications.rb
class CreatePublications < ActiveRecord::Migration[8.1]
  def change
    create_table :publications do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.string :tagline
      t.text :description
      t.string :custom_domain
      t.string :subdomain
      t.string :logo
      t.string :favicon
      t.string :accent_color, default: "#000000"
      t.string :twitter_handle
      t.string :facebook_url
      t.string :instagram_handle
      t.string :discord_invite_url
      t.boolean :comments_enabled, default: true
      t.boolean :subscriber_only_comments, default: false
      t.boolean :require_comment_approval, default: false
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :publications, :slug, unique: true
    add_index :publications, :subdomain, unique: true
    add_index :publications, :custom_domain, unique: true
    add_index :publications, :account_id
    
    add_foreign_key :publications, :accounts, column: :account_id, on_delete: :cascade
  end
end
```

### Posts
The core content unit with support for versioning, templates, and various post types.

```ruby
# db/migrate/xxx_create_posts.rb
class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :publication, null: false, foreign_key: { on_delete: :cascade }
      t.references :template, foreign_key: { to_table: :post_templates, on_delete: :nullify }
      t.references :series, foreign_key: { on_delete: :nullify }
      
      t.string :title, null: false
      t.string :slug, null: false
      t.text :subtitle
      t.text :content                    # Rich text via Action Text
      t.text :content_plain_text         # For plain text emails
      t.text :preview_text               # Email preview snippet
      t.text :excerpt                    # Auto-generated or manual
      
      # SEO fields
      t.string :meta_title
      t.text :meta_description
      t.string :canonical_url
      t.boolean :noindex, default: false
      t.string :og_image
      t.string :og_title
      t.text :og_description
      
      # Publishing
      t.string :status, default: "draft" # draft, scheduled, published, archived
      t.string :visibility, default: "public" # public, subscribers, paid
      t.datetime :published_at
      t.datetime :scheduled_at
      t.datetime :send_at               # When to send email
      t.boolean :email_sent, default: false
      t.datetime :email_sent_at
      
      # Post type
      t.string :post_type, default: "post" # post, discussion, podcast, page
      
      # Features
      t.boolean :pinned, default: false
      t.integer :pinned_position
      t.boolean :comments_enabled, default: true
      t.boolean :featured, default: false
      
      # Series position
      t.integer :series_position
      
      # Stats (denormalized for performance)
      t.integer :views_count, default: 0
      t.integer :unique_views_count, default: 0
      t.integer :email_opens_count, default: 0
      t.integer :email_clicks_count, default: 0
      t.integer :comments_count, default: 0
      t.integer :likes_count, default: 0
      t.integer :bookmarks_count, default: 0
      
      # Reading
      t.integer :word_count, default: 0
      t.integer :reading_time_minutes, default: 0

      t.timestamps
    end

    add_index :posts, [:publication_id, :slug], unique: true
    add_index :posts, [:publication_id, :status]
    add_index :posts, [:publication_id, :published_at]
    add_index :posts, [:publication_id, :pinned, :pinned_position]
    add_index :posts, :scheduled_at, where: "status = 'scheduled'"
  end
end
```

### Post Versions (Revision History)

```ruby
# db/migrate/xxx_create_post_versions.rb
class CreatePostVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :post_versions do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :user_id, null: false
      
      t.string :title
      t.text :subtitle
      t.text :content
      t.text :content_plain_text
      t.integer :version_number, null: false
      t.string :change_summary
      t.jsonb :diff_from_previous      # Store diff for efficient comparison

      t.timestamps
    end

    add_index :post_versions, [:post_id, :version_number], unique: true
    add_index :post_versions, [:post_id, :created_at]
    add_index :post_versions, :user_id
    
    add_foreign_key :post_versions, :users, column: :user_id, on_delete: :cascade
  end
end
```

### Post Authors (Co-authoring)

```ruby
# db/migrate/xxx_create_post_authors.rb
class CreatePostAuthors < ActiveRecord::Migration[8.1]
  def change
    create_table :post_authors do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :user_id, null: false
      
      t.string :role, default: "author"  # primary, author, contributor, editor
      t.integer :position, default: 0    # Display order
      t.text :author_note                # Per-post author bio
      t.boolean :notify_on_publish, default: true

      t.timestamps
    end

    add_index :post_authors, [:post_id, :user_id], unique: true
    add_index :post_authors, [:post_id, :position]
    add_index :post_authors, :user_id
    
    add_foreign_key :post_authors, :users, column: :user_id, on_delete: :cascade
  end
end
```

### Post Templates

```ruby
# db/migrate/xxx_create_post_templates.rb
class CreatePostTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :post_templates do |t|
      t.references :publication, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :created_by_id, null: false
      
      t.string :name, null: false
      t.text :description
      t.text :content                    # Template content with placeholders
      t.text :content_plain_text
      t.jsonb :structure                 # Structured template definition
      t.boolean :system_template, default: false
      t.integer :usage_count, default: 0

      t.timestamps
    end

    add_index :post_templates, [:publication_id, :name], unique: true
    add_index :post_templates, :created_by_id
    
    add_foreign_key :post_templates, :users, column: :created_by_id, on_delete: :restrict
  end
end
```

### Tags

```ruby
# db/migrate/xxx_create_tags.rb
class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :publication, null: false, foreign_key: true
      
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :color
      t.integer :posts_count, default: 0
      t.boolean :visible, default: true  # Show on public site

      t.timestamps
    end

    add_index :tags, [:publication_id, :slug], unique: true
    add_index :tags, [:publication_id, :name], unique: true
  end
end

# db/migrate/xxx_create_post_tags.rb
class CreatePostTags < ActiveRecord::Migration[8.1]
  def change
    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.references :tag, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :post_tags, [:post_id, :tag_id], unique: true
  end
end
```

### Series (Collections)

```ruby
# db/migrate/xxx_create_series.rb
class CreateSeries < ActiveRecord::Migration[8.1]
  def change
    create_table :series do |t|
      t.references :publication, null: false, foreign_key: true
      
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :cover_image
      t.string :status, default: "active"  # active, completed, archived
      t.integer :posts_count, default: 0
      t.boolean :numbered, default: true   # Show part numbers
      t.string :visibility, default: "public"

      t.timestamps
    end

    add_index :series, [:publication_id, :slug], unique: true
  end
end
```

### Footnotes & Sidenotes

```ruby
# db/migrate/xxx_create_footnotes.rb
class CreateFootnotes < ActiveRecord::Migration[8.1]
  def change
    create_table :footnotes do |t|
      t.references :post, null: false, foreign_key: true
      
      t.integer :number, null: false
      t.text :content, null: false
      t.string :footnote_type, default: "footnote"  # footnote, sidenote, marginnote
      t.string :marker                              # Custom marker if not numbered

      t.timestamps
    end

    add_index :footnotes, [:post_id, :number], unique: true
  end
end
```

### Content Embeds

```ruby
# db/migrate/xxx_create_embeds.rb
class CreateEmbeds < ActiveRecord::Migration[8.1]
  def change
    create_table :embeds do |t|
      t.references :post, null: false, foreign_key: true
      
      t.string :embed_type, null: false  # youtube, twitter, spotify, codepen, gist, etc.
      t.string :url, null: false
      t.string :embed_id                 # Platform-specific ID
      t.jsonb :metadata                  # Title, thumbnail, author, etc.
      t.text :html_cache                 # Cached embed HTML
      t.datetime :cached_at

      t.timestamps
    end

    add_index :embeds, [:post_id, :url], unique: true
  end
end
```

### Images (with optimization tracking)

```ruby
# db/migrate/xxx_create_post_images.rb
class CreatePostImages < ActiveRecord::Migration[8.1]
  def change
    create_table :post_images do |t|
      t.references :post, null: false, foreign_key: true
      
      t.string :alt_text                 # Accessibility
      t.string :caption
      t.string :credit
      t.string :credit_url
      t.boolean :alt_text_prompted, default: false
      t.jsonb :variants                  # Cached variant URLs
      t.integer :width
      t.integer :height
      t.integer :file_size
      t.string :format

      t.timestamps
    end
  end
end
```

---

## Phase 2: Subscriber Management

### Subscribers

```ruby
# db/migrate/xxx_create_subscribers.rb
class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.references :publication, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :identity_id  # If they have an account
      
      t.string :email_address, null: false
      t.string :name
      t.string :status, default: "active"  # pending, active, unsubscribed, bounced, complained
      
      # Subscription details
      t.string :subscription_type, default: "free"  # free, paid, comp
      t.datetime :subscribed_at
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at
      t.string :unsubscribe_reason
      t.string :source                    # How they subscribed
      t.string :referrer_url
      
      # Engagement scoring
      t.decimal :engagement_score, precision: 5, scale: 2, default: 0
      t.integer :emails_received, default: 0
      t.integer :emails_opened, default: 0
      t.integer :emails_clicked, default: 0
      t.integer :posts_read, default: 0
      t.integer :comments_count, default: 0
      t.datetime :last_opened_at
      t.datetime :last_clicked_at
      t.datetime :last_active_at
      
      # Send time optimization
      t.jsonb :open_time_histogram       # Hour-by-hour open distribution
      t.integer :optimal_send_hour       # Best hour to send (0-23)
      t.string :timezone
      
      # Cohort tracking
      t.date :cohort_date                # Month/year they joined
      
      # Custom fields
      t.jsonb :custom_fields, default: {}

      t.timestamps
    end

    add_index :subscribers, [:publication_id, :email_address], unique: true
    add_index :subscribers, [:publication_id, :status]
    add_index :subscribers, [:publication_id, :subscription_type]
    add_index :subscribers, [:publication_id, :engagement_score]
    add_index :subscribers, [:publication_id, :cohort_date]
    add_index :subscribers, :email_address
    add_index :subscribers, :identity_id
    
    add_foreign_key :subscribers, :identities, column: :identity_id, on_delete: :nullify
  end
end
```

### Subscriber Tags

```ruby
# db/migrate/xxx_create_subscriber_tag_definitions.rb
class CreateSubscriberTagDefinitions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriber_tag_definitions do |t|
      t.references :publication, null: false, foreign_key: true
      
      t.string :name, null: false
      t.string :slug, null: false
      t.string :color
      t.text :description
      t.string :tag_type, default: "manual"  # manual, automatic, import
      t.jsonb :auto_rules                     # Rules for automatic tagging
      t.integer :subscribers_count, default: 0

      t.timestamps
    end

    add_index :subscriber_tag_definitions, [:publication_id, :slug], unique: true
  end
end

# db/migrate/xxx_create_subscriber_tags.rb
class CreateSubscriberTags < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriber_tags do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      t.references :subscriber_tag_definition, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :applied_by_id
      
      t.string :source, default: "manual"  # manual, import, automation

      t.timestamps
    end

    add_index :subscriber_tags, [:subscriber_id, :subscriber_tag_definition_id], 
              unique: true, name: "idx_subscriber_tags_unique"
    add_index :subscriber_tags, :applied_by_id
    
    add_foreign_key :subscriber_tags, :users, column: :applied_by_id, on_delete: :nullify
  end
end
```

### Subscriber Notes

```ruby
# db/migrate/xxx_create_subscriber_notes.rb
class CreateSubscriberNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriber_notes do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :user_id, null: false
      
      t.text :content, null: false
      t.boolean :pinned, default: false

      t.timestamps
    end

    add_index :subscriber_notes, [:subscriber_id, :created_at]
    add_index :subscriber_notes, :user_id
    
    add_foreign_key :subscriber_notes, :users, column: :user_id, on_delete: :cascade
  end
end
```

### Suppression List

```ruby
# db/migrate/xxx_create_suppression_entries.rb
class CreateSuppressionEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :suppression_entries do |t|
      t.references :publication, foreign_key: { on_delete: :cascade }  # null = global
      
      t.string :email_address, null: false
      t.string :reason, null: false      # bounce, complaint, unsubscribe, manual
      t.string :bounce_type              # hard, soft
      t.text :details
      t.datetime :suppressed_at, null: false

      t.timestamps
    end

    add_index :suppression_entries, :email_address
    add_index :suppression_entries, [:publication_id, :email_address]
  end
end
```

### Email Preferences

```ruby
# db/migrate/xxx_create_email_preferences.rb
class CreateEmailPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :email_preferences do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      
      t.string :frequency, default: "immediate"  # immediate, daily_digest, weekly_digest
      t.string :digest_day                       # For weekly: monday, tuesday, etc.
      t.integer :digest_hour, default: 9         # Hour to send digest
      t.jsonb :section_preferences, default: {}  # Per-section settings
      t.boolean :marketing_emails, default: true
      t.boolean :comment_notifications, default: true
      t.boolean :reply_notifications, default: true

      t.timestamps
    end

    add_index :email_preferences, :subscriber_id, unique: true
  end
end
```

---

## Phase 3: Email Delivery

### Email Campaigns

```ruby
# db/migrate/xxx_create_email_campaigns.rb
class CreateEmailCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :email_campaigns do |t|
      t.references :publication, null: false, foreign_key: { on_delete: :cascade }
      t.references :post, foreign_key: { on_delete: :nullify }
      
      t.string :campaign_type, default: "post"  # post, resend, digest, welcome, custom
      t.string :status, default: "draft"        # draft, scheduled, sending, sent, cancelled
      t.string :subject, null: false
      t.string :preview_text
      t.text :content_html
      t.text :content_plain
      t.string :from_name
      t.string :reply_to
      
      # Targeting
      t.string :audience, default: "all"        # all, free, paid, tag, segment
      t.jsonb :audience_criteria
      
      # Stats
      t.integer :recipients_count, default: 0
      t.integer :sent_count, default: 0
      t.integer :delivered_count, default: 0
      t.integer :opened_count, default: 0
      t.integer :clicked_count, default: 0
      t.integer :bounced_count, default: 0
      t.integer :complained_count, default: 0
      t.integer :unsubscribed_count, default: 0
      
      # Timing
      t.datetime :scheduled_at
      t.datetime :started_at
      t.datetime :completed_at
      
      # Resend settings
      t.references :original_campaign, foreign_key: { to_table: :email_campaigns, on_delete: :nullify }
      t.string :resend_subject                  # Different subject for resend

      t.timestamps
    end

    add_index :email_campaigns, [:publication_id, :status]
    add_index :email_campaigns, :scheduled_at, where: "status = 'scheduled'"
  end
end
```

### Email Deliveries (Individual sends)

```ruby
# db/migrate/xxx_create_email_deliveries.rb
class CreateEmailDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :email_deliveries do |t|
      t.references :email_campaign, null: false, foreign_key: { on_delete: :cascade }
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      
      t.string :status, default: "pending"  # pending, sent, delivered, opened, clicked, bounced, complained
      t.string :message_id                  # Email provider message ID
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :first_opened_at
      t.datetime :last_opened_at
      t.integer :open_count, default: 0
      t.datetime :first_clicked_at
      t.integer :click_count, default: 0
      t.datetime :bounced_at
      t.string :bounce_type
      t.text :bounce_message
      t.datetime :complained_at

      t.timestamps
    end

    add_index :email_deliveries, [:email_campaign_id, :subscriber_id], unique: true
    add_index :email_deliveries, [:email_campaign_id, :status]
    add_index :email_deliveries, :message_id, unique: true
    add_index :email_deliveries, :sent_at
  end
end
```

### Email Clicks

```ruby
# db/migrate/xxx_create_email_clicks.rb
class CreateEmailClicks < ActiveRecord::Migration[8.1]
  def change
    create_table :email_clicks do |t|
      t.references :email_delivery, null: false, foreign_key: { on_delete: :cascade }
      
      t.string :url, null: false
      t.string :link_id                    # For tracking specific links
      t.string :user_agent
      t.string :ip_address
      t.datetime :clicked_at, null: false

      t.timestamps
    end

    add_index :email_clicks, [:email_delivery_id, :clicked_at]
    add_index :email_clicks, :url
  end
end
```

---

## Phase 4: Comments & Community

### Comments (Threaded)

```ruby
# db/migrate/xxx_create_comments.rb
class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      t.references :parent, foreign_key: { to_table: :comments, on_delete: :cascade }
      t.references :subscriber, foreign_key: { on_delete: :cascade }
      t.bigint :user_id  # For author comments
      
      t.text :content, null: false
      t.string :status, default: "pending"  # pending, approved, rejected, spam
      t.boolean :is_author, default: false  # Highlighted author comment
      t.boolean :is_pinned, default: false
      t.boolean :edited, default: false
      t.datetime :edited_at
      
      # Stats
      t.integer :votes_count, default: 0
      t.integer :replies_count, default: 0
      
      # Moderation
      t.bigint :approved_by_id
      t.datetime :approved_at
      t.text :rejection_reason
      
      # Metadata
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end

    add_index :comments, [:post_id, :status, :created_at]
    add_index :comments, [:post_id, :parent_id]
    add_index :comments, :subscriber_id
    add_index :comments, :status
    add_index :comments, :user_id
    add_index :comments, :approved_by_id
    
    add_foreign_key :comments, :users, column: :user_id, on_delete: :cascade
    add_foreign_key :comments, :users, column: :approved_by_id, on_delete: :nullify
  end
end
```

### Comment Votes

```ruby
# db/migrate/xxx_create_comment_votes.rb
class CreateCommentVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_votes do |t|
      t.references :comment, null: false, foreign_key: { on_delete: :cascade }
      t.references :subscriber, foreign_key: { on_delete: :cascade }
      t.bigint :user_id
      
      t.integer :value, null: false, default: 1  # 1 = upvote, -1 = downvote

      t.timestamps
    end

    add_index :comment_votes, [:comment_id, :subscriber_id], unique: true, where: "subscriber_id IS NOT NULL"
    add_index :comment_votes, [:comment_id, :user_id], unique: true, where: "user_id IS NOT NULL"
    
    add_foreign_key :comment_votes, :users, column: :user_id, on_delete: :cascade
  end
end
```

### Comment Notifications

```ruby
# db/migrate/xxx_create_comment_notifications.rb
class CreateCommentNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_notifications do |t|
      t.references :comment, null: false, foreign_key: { on_delete: :cascade }
      t.references :subscriber, foreign_key: { on_delete: :cascade }
      t.bigint :user_id
      
      t.string :notification_type, null: false  # reply, mention, author_reply
      t.string :status, default: "pending"      # pending, sent, read
      t.datetime :sent_at
      t.datetime :read_at

      t.timestamps
    end

    add_index :comment_notifications, [:subscriber_id, :status], where: "subscriber_id IS NOT NULL"
    add_index :comment_notifications, [:user_id, :status], where: "user_id IS NOT NULL"
    
    add_foreign_key :comment_notifications, :users, column: :user_id, on_delete: :cascade
  end
end
```

### Polls & Surveys

```ruby
# db/migrate/xxx_create_polls.rb
class CreatePolls < ActiveRecord::Migration[8.1]
  def change
    create_table :polls do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      
      t.string :question, null: false
      t.string :poll_type, default: "single"  # single, multiple, rating, open
      t.boolean :show_results, default: true
      t.boolean :allow_other, default: false
      t.datetime :closes_at
      t.integer :responses_count, default: 0

      t.timestamps
    end
  end
end

# db/migrate/xxx_create_poll_options.rb
class CreatePollOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :poll_options do |t|
      t.references :poll, null: false, foreign_key: { on_delete: :cascade }
      
      t.string :text, null: false
      t.integer :position, default: 0
      t.integer :votes_count, default: 0

      t.timestamps
    end

    add_index :poll_options, [:poll_id, :position]
  end
end

# db/migrate/xxx_create_poll_responses.rb
class CreatePollResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :poll_responses do |t|
      t.references :poll, null: false, foreign_key: { on_delete: :cascade }
      t.references :poll_option, foreign_key: { on_delete: :cascade }
      t.references :subscriber, foreign_key: { on_delete: :cascade }
      
      t.text :open_response               # For open-ended polls
      t.integer :rating                   # For rating polls

      t.timestamps
    end

    add_index :poll_responses, [:poll_id, :subscriber_id]
  end
end
```

---

## Phase 5: Reader Experience

### Bookmarks

```ruby
# db/migrate/xxx_create_bookmarks.rb
class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmarks do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      
      t.text :note                        # Personal note about bookmark

      t.timestamps
    end

    add_index :bookmarks, [:subscriber_id, :post_id], unique: true
    add_index :bookmarks, [:subscriber_id, :created_at]
  end
end
```

### Highlights & Annotations

```ruby
# db/migrate/xxx_create_highlights.rb
class CreateHighlights < ActiveRecord::Migration[8.1]
  def change
    create_table :highlights do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      
      t.text :selected_text, null: false
      t.text :note                        # Personal annotation
      t.string :color, default: "yellow"
      t.jsonb :position                   # Start/end position in content

      t.timestamps
    end

    add_index :highlights, [:subscriber_id, :post_id]
    add_index :highlights, [:subscriber_id, :created_at]
  end
end
```

### Reading History

```ruby
# db/migrate/xxx_create_reading_history_entries.rb
class CreateReadingHistoryEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_history_entries do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :progress_percent, default: 0    # 0-100
      t.integer :time_spent_seconds, default: 0
      t.integer :scroll_depth_percent, default: 0
      t.string :source                           # web, email, app

      t.timestamps
    end

    add_index :reading_history_entries, [:subscriber_id, :post_id], unique: true
    add_index :reading_history_entries, [:subscriber_id, :started_at]
  end
end
```

---

## Phase 6: Analytics

### Cohort Analysis

```ruby
# db/migrate/xxx_create_cohort_snapshots.rb
class CreateCohortSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :cohort_snapshots do |t|
      t.references :publication, null: false, foreign_key: true
      
      t.date :cohort_date, null: false           # Month the cohort joined
      t.date :snapshot_date, null: false         # When this measurement was taken
      t.integer :months_since_join, null: false
      
      t.integer :initial_count, null: false      # How many in cohort originally
      t.integer :remaining_count, null: false    # How many still active
      t.decimal :retention_rate, precision: 5, scale: 2
      
      # Engagement metrics
      t.decimal :avg_open_rate, precision: 5, scale: 2
      t.decimal :avg_click_rate, precision: 5, scale: 2
      t.integer :upgraded_to_paid, default: 0

      t.timestamps
    end

    add_index :cohort_snapshots, [:publication_id, :cohort_date, :snapshot_date], 
              unique: true, name: "idx_cohort_snapshots_unique"
  end
end
```

---

## Phase 7: Security & Administration

### Audit Logs

```ruby
# db/migrate/xxx_create_audit_logs.rb
class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id
      
      t.string :action, null: false           # create, update, delete, login, etc.
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.jsonb :changes_made, default: {}
      t.jsonb :metadata, default: {}
      t.string :ip_address
      t.string :user_agent
      t.string :request_id

      t.timestamps
    end

    add_index :audit_logs, [:account_id, :created_at]
    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, [:user_id, :created_at], where: "user_id IS NOT NULL"
    add_index :audit_logs, :action
    
    add_foreign_key :audit_logs, :accounts, column: :account_id, on_delete: :cascade
    add_foreign_key :audit_logs, :users, column: :user_id, on_delete: :nullify
  end
end
```

### Two-Factor Authentication

```ruby
# db/migrate/xxx_create_two_factor_credentials.rb
class CreateTwoFactorCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :two_factor_credentials do |t|
      t.bigint :identity_id, null: false
      
      t.string :credential_type, null: false    # totp, webauthn, backup_codes
      t.string :otp_secret                      # For TOTP
      t.jsonb :webauthn_credentials, default: []  # For WebAuthn
      t.text :backup_codes_encrypted            # Encrypted backup codes
      t.boolean :enabled, default: false
      t.datetime :last_used_at
      t.datetime :verified_at

      t.timestamps
    end

    add_index :two_factor_credentials, [:identity_id, :credential_type], unique: true
    
    add_foreign_key :two_factor_credentials, :identities, column: :identity_id, on_delete: :cascade
  end
end
```

### Rate Limiting

```ruby
# db/migrate/xxx_create_rate_limit_records.rb
class CreateRateLimitRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :rate_limit_records do |t|
      t.string :key, null: false              # Composite key (action:identifier)
      t.integer :count, default: 0
      t.datetime :window_start, null: false
      t.datetime :blocked_until

      t.timestamps
    end

    add_index :rate_limit_records, [:key, :window_start], unique: true
    add_index :rate_limit_records, :blocked_until
  end
end
```

---

## Phase 8: SEO

### Social Cards

```ruby
# db/migrate/xxx_create_social_cards.rb
class CreateSocialCards < ActiveRecord::Migration[8.1]
  def change
    create_table :social_cards do |t|
      t.references :post, null: false, foreign_key: { on_delete: :cascade }
      
      t.string :platform, null: false         # twitter, facebook, linkedin
      t.string :title
      t.text :description
      t.string :image
      t.string :card_type                     # summary, summary_large_image, etc.

      t.timestamps
    end

    add_index :social_cards, [:post_id, :platform], unique: true
  end
end
```

---

## Additional Tables

### Community Directory

```ruby
# db/migrate/xxx_create_community_profiles.rb
class CreateCommunityProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :community_profiles do |t|
      t.references :subscriber, null: false, foreign_key: { on_delete: :cascade }
      
      t.string :display_name
      t.text :bio
      t.string :website
      t.string :twitter_handle
      t.string :linkedin_url
      t.boolean :visible_in_directory, default: false
      t.boolean :allow_messages, default: false
      t.jsonb :interests, default: []

      t.timestamps
    end

    add_index :community_profiles, :subscriber_id, unique: true
    add_index :community_profiles, :visible_in_directory
  end
end
```

### External Integrations

```ruby
# db/migrate/xxx_create_integrations.rb
class CreateIntegrations < ActiveRecord::Migration[8.1]
  def change
    create_table :integrations do |t|
      t.references :publication, null: false, foreign_key: true
      
      t.string :provider, null: false         # discord, slack, zapier, etc.
      t.string :status, default: "active"
      t.jsonb :settings, default: {}
      t.string :webhook_url
      t.text :access_token_encrypted
      t.text :refresh_token_encrypted
      t.datetime :token_expires_at

      t.timestamps
    end

    add_index :integrations, [:publication_id, :provider], unique: true
  end
end
```

---

## URL-Friendly Identifiers (Optional)

If you want to hide sequential IDs in public URLs, add a `public_id` column:

```ruby
# app/models/concerns/has_public_id.rb
module HasPublicId
  extend ActiveSupport::Concern

  included do
    before_create :generate_public_id
  end

  class_methods do
    def find_by_public_id(id)
      find_by(public_id: id)
    end

    def find_by_public_id!(id)
      find_by!(public_id: id)
    end
  end

  private

  def generate_public_id
    self.public_id ||= SecureRandom.alphanumeric(12).downcase
  end
end
```

Add to tables that appear in URLs:

```ruby
# db/migrate/xxx_add_public_id_to_posts.rb
class AddPublicIdToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :public_id, :string, limit: 12
    add_index :posts, :public_id, unique: true
  end
end
```

---

## Summary: Table Count by Phase

| Phase | New Tables | Description |
|-------|------------|-------------|
| 1 | 11 | Publications, Posts, PostVersions, PostAuthors, PostTemplates, Tags, PostTags, Series, Footnotes, Embeds, PostImages |
| 2 | 6 | Subscribers, SubscriberTagDefinitions, SubscriberTags, SubscriberNotes, SuppressionEntries, EmailPreferences |
| 3 | 3 | EmailCampaigns, EmailDeliveries, EmailClicks |
| 4 | 6 | Comments, CommentVotes, CommentNotifications, Polls, PollOptions, PollResponses |
| 5 | 3 | Bookmarks, Highlights, ReadingHistoryEntries |
| 6 | 1 | CohortSnapshots |
| 7 | 3 | AuditLogs, TwoFactorCredentials, RateLimitRecords |
| 8 | 1 | SocialCards |
| Other | 2 | CommunityProfiles, Integrations |

**Total: ~36 new tables**

---

## Benefits of Integer IDs over UUIDs

1. **Simpler** - No custom type registration needed
2. **Smaller storage** - 8 bytes vs 16 bytes per ID
3. **Faster joins** - Integer comparison is faster than binary
4. **Better index performance** - Sequential IDs cluster better
5. **Easier debugging** - Human-readable IDs
6. **Native Rails support** - No custom serialization
7. **SQLite friendly** - No binary column handling issues

---

## Concerns to Extract

1. **Sluggable** - Shared slug generation logic
2. **Publishable** - Status management, scheduling
3. **Auditable** - Automatic audit logging
4. **Engageable** - Engagement score calculation
5. **Searchable** - Full-text search integration
6. **Versionable** - Automatic version creation
7. **HasPublicId** - URL-safe identifiers

---

## Background Jobs Needed

1. **EmailDeliveryJob** - Send individual emails
2. **EngagementScoreCalculatorJob** - Recalculate scores
3. **CohortSnapshotJob** - Generate cohort data
4. **DigestEmailJob** - Compile and send digests
5. **SendTimeOptimizerJob** - Analyze open patterns
6. **EmbedCacheRefreshJob** - Update embed previews
7. **ImageOptimizationJob** - Generate variants
8. **SitemapGeneratorJob** - Rebuild sitemap

---

## Foreign Key Relationships & Cascade Behavior

### Cascade Delete (ON DELETE CASCADE)
When parent is deleted, child records are automatically deleted:

**Account → Publication → Everything**
- `accounts` → `publications` → `posts`, `tags`, `series`, `subscribers`, etc.
- Deleting an account removes all publications and all their content

**Publication-level cascades:**
- `publications` → `posts`, `tags`, `series`, `subscribers`, `email_campaigns`
- `posts` → `post_versions`, `post_authors`, `footnotes`, `embeds`, `post_images`, `comments`, `bookmarks`, `highlights`
- `subscribers` → `subscriber_tags`, `subscriber_notes`, `email_preferences`, `bookmarks`, `highlights`
- `email_campaigns` → `email_deliveries` → `email_clicks`
- `comments` → `comment_votes`, `comment_notifications` (including nested comments)

### Nullify (ON DELETE SET NULL)
When parent is deleted, foreign key is set to NULL:

- `post_templates` → `posts.template_id` (posts keep content, lose template reference)
- `series` → `posts.series_id` (posts remain standalone)
- `identities` → `subscribers.identity_id` (subscribers can exist without accounts)
- `email_campaigns` → `email_campaigns.original_campaign_id` (resend campaigns lose original reference)
- `users` → `subscriber_tags.applied_by_id`, `comments.approved_by_id`, `audit_logs.user_id`

### Restrict (ON DELETE RESTRICT) 
Prevents deletion if child records exist:

- `users` → `post_templates.created_by_id` (can't delete user who created system templates)

### Key Benefits:

1. **Data Integrity**: Prevents orphaned records and referential integrity violations
2. **Logical Deletion Flow**: Account deletion cleanly removes all associated data
3. **Flexibility**: Templates and series can be deleted without affecting posts
4. **Audit Trail**: Important relationships (like template creators) are protected
5. **Performance**: Database handles cascading automatically without application logic

### Special Considerations:

- **Soft Deletes**: Consider implementing soft deletes for critical entities like posts and subscribers
- **Backup Strategy**: Cascade deletes are irreversible - ensure proper backup procedures
- **Bulk Operations**: Large cascade deletes may need to be batched for performance
