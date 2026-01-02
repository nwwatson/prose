# Prose Implementation Roadmap

## Overview

This roadmap breaks down the feature list into manageable sprints with realistic time estimates for a small team (1-2 developers).

**Total Estimated Duration:** 6-9 months
**Recommended Team Size:** 2-3 developers
**Primary Keys:** Standard auto-incrementing integers (bigint)

---

## Phase 1: Core Publishing Foundation
**Duration: 6-8 weeks**

### Sprint 1.1: Publications & Posts (2 weeks)

#### Tasks
- [ ] Create Publication model and migrations
- [ ] Create Post model with all fields
- [ ] Build publication settings UI
- [ ] Implement post creation flow
- [ ] Set up Action Text for rich content
- [ ] Add slug generation with uniqueness
- [ ] Implement post status workflow (draft → scheduled → published)
- [ ] Build post listing and filtering

#### Deliverables
- Publishers can create publications
- Basic post creation and editing
- Post scheduling

---

### Sprint 1.2: Post Versioning & Templates (2 weeks)

#### Tasks
- [ ] Create PostVersion model
- [ ] Implement automatic versioning on save
- [ ] Build version comparison UI (diff view)
- [ ] Version restore functionality
- [ ] Create PostTemplate model
- [ ] Template creation UI
- [ ] Apply template to new post
- [ ] System templates (Weekly Roundup, Q&A, etc.)

#### Dependencies
- Sprint 1.1 complete

#### Deliverables
- Full revision history with restore
- Reusable post templates

---

### Sprint 1.3: Co-authoring & Tags (2 weeks)

#### Tasks
- [ ] Create PostAuthor join model
- [ ] Multi-author selection UI
- [ ] Author attribution display
- [ ] Per-author notification settings
- [ ] Create Tag model
- [ ] Tag management UI
- [ ] Post tagging interface
- [ ] Tag-based post filtering
- [ ] Tag pages on public site

#### Dependencies
- Sprint 1.1 complete

#### Deliverables
- Multiple authors per post
- Full tagging system

---

### Sprint 1.4: Series, Footnotes & Embeds (2 weeks)

#### Tasks
- [ ] Create Series model
- [ ] Series management UI
- [ ] Assign posts to series with ordering
- [ ] Series navigation on posts
- [ ] Create Footnote model
- [ ] Footnote/sidenote insertion in editor
- [ ] Footnote rendering (inline, end, margin)
- [ ] Create Embed model
- [ ] oEmbed integration for supported platforms
- [ ] Embed caching system
- [ ] Syntax highlighting with Prism.js or highlight.js
- [ ] Pinned posts functionality

#### Dependencies
- Sprint 1.1 complete

#### Deliverables
- Organized content series
- Academic-style footnotes
- Rich embeds from Twitter, YouTube, etc.
- Code syntax highlighting

---

## Phase 2: Subscriber Management
**Duration: 4-5 weeks**

### Sprint 2.1: Core Subscriber System (2 weeks)

#### Tasks
- [ ] Create Subscriber model
- [ ] Subscription flow (signup form)
- [ ] Double opt-in confirmation
- [ ] Subscriber list UI with search/filter
- [ ] Subscriber detail view
- [ ] Manual subscriber addition
- [ ] CSV import/export
- [ ] Unsubscribe handling
- [ ] Create SuppressionEntry model
- [ ] Bounce/complaint processing

#### Dependencies
- Phase 1 complete

#### Deliverables
- Full subscriber management
- Import/export capabilities
- Suppression list handling

---

### Sprint 2.2: Subscriber Tags & Notes (1.5 weeks)

#### Tasks
- [ ] Create SubscriberTagDefinition model
- [ ] Create SubscriberTag join model
- [ ] Tag management UI
- [ ] Bulk tagging interface
- [ ] Tag-based filtering
- [ ] Create SubscriberNote model
- [ ] Notes UI on subscriber detail
- [ ] Pinned notes feature

#### Dependencies
- Sprint 2.1 complete

#### Deliverables
- Subscriber organization via tags
- Private notes system

---

### Sprint 2.3: Email Preferences & Bulk Actions (1.5 weeks)

#### Tasks
- [ ] Create EmailPreference model
- [ ] Preference management UI for subscribers
- [ ] Digest frequency options
- [ ] Section-based preferences
- [ ] Bulk action framework
- [ ] Bulk tag/untag
- [ ] Bulk delete
- [ ] Bulk export
- [ ] Selection UI with filters

#### Dependencies
- Sprint 2.1 & 2.2 complete

#### Deliverables
- Subscriber-controlled email preferences
- Efficient bulk operations

---

## Phase 3: Email Delivery Enhancement
**Duration: 4-5 weeks**

### Sprint 3.1: Email Campaign System (2 weeks)

#### Tasks
- [ ] Create EmailCampaign model
- [ ] Create EmailDelivery model
- [ ] Create EmailClick model
- [ ] Campaign creation UI
- [ ] Preview text editor
- [ ] Plain text version editor
- [ ] Audience targeting (all, free, paid, tagged)
- [ ] Campaign scheduling
- [ ] Email queue processing with Solid Queue
- [ ] Delivery status tracking

#### Dependencies
- Phase 2 complete

#### Deliverables
- Full email campaign management
- Targeted sending

---

### Sprint 3.2: Email Analytics & Optimization (2 weeks)

#### Tasks
- [ ] Open tracking (pixel)
- [ ] Click tracking (link rewriting)
- [ ] Campaign stats dashboard
- [ ] Per-subscriber engagement updates
- [ ] Open time histogram collection
- [ ] Basic send time optimization
- [ ] Resend to non-openers feature
- [ ] Different subject line for resend

#### Dependencies
- Sprint 3.1 complete

#### Deliverables
- Comprehensive email analytics
- Resend campaigns
- Send time insights

---

### Sprint 3.3: Email Performance & Templates (1 week)

#### Tasks
- [ ] Email template compilation optimization
- [ ] Template caching
- [ ] Background job prioritization
- [ ] Email preview rendering
- [ ] Mobile-responsive email templates
- [ ] Dark mode email support

#### Dependencies
- Sprint 3.1 complete

#### Deliverables
- Fast email rendering
- Beautiful, responsive emails

---

## Phase 4: Comments & Community
**Duration: 5-6 weeks**

### Sprint 4.1: Threaded Comments (2 weeks)

#### Tasks
- [ ] Create Comment model with self-referential parent
- [ ] Comment submission UI
- [ ] Threaded display with Turbo
- [ ] Real-time comment updates via Turbo Streams
- [ ] Reply functionality
- [ ] Author highlighting
- [ ] Edit/delete own comments
- [ ] Subscriber-only comments toggle

#### Dependencies
- Subscriber system (Phase 2)

#### Deliverables
- Full threaded commenting system
- Real-time updates

---

### Sprint 4.2: Comment Moderation & Voting (2 weeks)

#### Tasks
- [ ] Moderation queue UI
- [ ] Approve/reject workflow
- [ ] Spam detection basics
- [ ] Create CommentVote model
- [ ] Upvote/downvote UI
- [ ] Vote count display
- [ ] Sort by votes option
- [ ] Comment pinning

#### Dependencies
- Sprint 4.1 complete

#### Deliverables
- Content moderation tools
- Community-driven ranking

---

### Sprint 4.3: Comment Notifications & Discussion Posts (1.5 weeks)

#### Tasks
- [ ] Create CommentNotification model
- [ ] Email notifications for replies
- [ ] Author reply notifications
- [ ] Notification preferences
- [ ] Discussion post type
- [ ] Discussion-specific UI
- [ ] Featured discussions

#### Dependencies
- Sprint 4.1 complete

#### Deliverables
- Notification system
- Discussion-focused posts

---

### Sprint 4.4: Polls & Surveys (1 week)

#### Tasks
- [ ] Create Poll, PollOption, PollResponse models
- [ ] Poll creation in post editor
- [ ] Single/multiple choice polls
- [ ] Results display
- [ ] Poll closing/expiration
- [ ] Anonymous vs. tracked responses

#### Dependencies
- Sprint 4.1 complete

#### Deliverables
- Interactive polls in posts

---

## Phase 5: Reader Experience
**Duration: 3-4 weeks**

### Sprint 5.1: Bookmarks & Reading History (1.5 weeks)

#### Tasks
- [ ] Create Bookmark model
- [ ] Save for later button
- [ ] Bookmarks list page
- [ ] Create ReadingHistoryEntry model
- [ ] Track post views
- [ ] Reading progress tracking
- [ ] Continue reading feature
- [ ] "Already read" indicators

#### Dependencies
- Subscriber authentication

#### Deliverables
- Personal reading list
- Reading history tracking

---

### Sprint 5.2: Highlights & Annotations (1.5 weeks)

#### Tasks
- [ ] Create Highlight model
- [ ] Text selection highlighting
- [ ] Annotation notes
- [ ] Highlight colors
- [ ] Highlights list page
- [ ] Export highlights

#### Dependencies
- Sprint 5.1 complete

#### Deliverables
- Personal note-taking on articles

---

### Sprint 5.3: Accessibility (1 week)

#### Tasks
- [ ] Alt text prompts in image upload
- [ ] Alt text requirement option
- [ ] Keyboard navigation audit
- [ ] Skip links
- [ ] ARIA labels audit
- [ ] Screen reader testing
- [ ] Font size controls
- [ ] High contrast mode option

#### Dependencies
- None (can run parallel)

#### Deliverables
- WCAG 2.1 AA compliance
- Accessible reading experience

---

## Phase 6: Analytics & Intelligence
**Duration: 2-3 weeks**

### Sprint 6.1: Engagement Scoring (1 week)

#### Tasks
- [ ] Define engagement score algorithm
- [ ] Create scoring background job
- [ ] Engagement score display
- [ ] Segment by engagement level
- [ ] Engagement trends over time

#### Dependencies
- Email tracking (Phase 3)
- Reading history (Phase 5)

#### Deliverables
- Subscriber engagement insights

---

### Sprint 6.2: Cohort Analysis (1 week)

#### Tasks
- [ ] Create CohortSnapshot model
- [ ] Cohort snapshot generation job
- [ ] Cohort retention chart
- [ ] Cohort comparison
- [ ] Export cohort data

#### Dependencies
- Subscriber system (Phase 2)

#### Deliverables
- Cohort-based retention analysis

---

### Sprint 6.3: ML Send Time Optimization (1 week)

#### Tasks
- [ ] Collect open time data
- [ ] Build time distribution model
- [ ] Predict optimal send time per subscriber
- [ ] A/B test send time effectiveness
- [ ] Dashboard for send time insights

#### Dependencies
- Email analytics (Phase 3)

#### Deliverables
- ML-powered send time optimization

---

## Phase 7: Community Features
**Duration: 2-3 weeks**

### Sprint 7.1: Community Directory (1.5 weeks)

#### Tasks
- [ ] Create CommunityProfile model
- [ ] Profile setup flow
- [ ] Directory listing page
- [ ] Profile visibility controls
- [ ] Search/filter directory
- [ ] Interest-based matching

#### Dependencies
- Subscriber system (Phase 2)

#### Deliverables
- Subscriber directory

---

### Sprint 7.2: External Integrations (1.5 weeks)

#### Tasks
- [ ] Create Integration model
- [ ] Discord webhook integration
- [ ] Slack webhook integration
- [ ] Webhook event system
- [ ] Integration management UI
- [ ] Integration health monitoring

#### Dependencies
- Basic publishing (Phase 1)

#### Deliverables
- Discord/Slack notifications
- Webhook system

---

## Phase 8: SEO & Security
**Duration: 3-4 weeks**

### Sprint 8.1: SEO Features (1.5 weeks)

#### Tasks
- [ ] Meta title/description fields
- [ ] OG image management
- [ ] Twitter Card support
- [ ] Create SocialCard model
- [ ] Canonical URL handling
- [ ] Noindex controls
- [ ] Sitemap generation job
- [ ] Sitemap controller
- [ ] Schema.org structured data
- [ ] robots.txt management

#### Dependencies
- Basic posts (Phase 1)

#### Deliverables
- Full SEO control
- Automated sitemap
- Rich snippets

---

### Sprint 8.2: Two-Factor Authentication (1 week)

#### Tasks
- [ ] Create TwoFactorCredential model
- [ ] TOTP implementation (Google Authenticator)
- [ ] Backup codes generation
- [ ] 2FA setup flow
- [ ] 2FA verification on login
- [ ] Recovery flow

#### Dependencies
- Authentication system

#### Deliverables
- Secure 2FA for publishers

---

### Sprint 8.3: Audit Logs & Rate Limiting (1.5 weeks)

#### Tasks
- [ ] Create AuditLog model
- [ ] Auditable concern
- [ ] Audit log viewer
- [ ] Filter/search audit logs
- [ ] Create RateLimitRecord model
- [ ] Rate limiting middleware
- [ ] Per-action rate limits
- [ ] Rate limit dashboard
- [ ] Block/unblock IP addresses

#### Dependencies
- Basic authentication

#### Deliverables
- Complete audit trail
- Abuse prevention

---

## Summary Timeline

```
Month 1-2:   Phase 1 (Core Publishing)
Month 2-3:   Phase 2 (Subscribers) + Phase 3 start (Email)
Month 3-4:   Phase 3 (Email) + Phase 4 start (Comments)
Month 4-5:   Phase 4 (Comments) + Phase 5 (Reader Experience)
Month 5-6:   Phase 6 (Analytics) + Phase 7 (Community)
Month 6-7:   Phase 8 (SEO & Security) + Polish
Month 7+:    Testing, bug fixes, launch prep
```

---

## Technical Considerations

### Database Strategy

Using standard integer primary keys throughout:

```ruby
# config/application.rb
config.generators do |g|
  g.orm :active_record, primary_key_type: :primary_key
end
```

For URL-safe identifiers on public-facing resources, use a separate `public_id` column:

```ruby
# app/models/concerns/has_public_id.rb
module HasPublicId
  extend ActiveSupport::Concern

  included do
    before_create :generate_public_id
  end

  def to_param
    public_id
  end

  private

  def generate_public_id
    self.public_id ||= SecureRandom.alphanumeric(12).downcase
  end
end
```

### Background Jobs Priority

```ruby
# config/solid_queue.yml
queues:
  - name: critical
    polling_interval: 0.1
    # Email delivery, notifications
    
  - name: default
    polling_interval: 1
    # Most jobs
    
  - name: low
    polling_interval: 5
    # Analytics, sitemap, cleanup
```

### Caching Strategy

1. **Fragment caching** for post rendering
2. **Russian doll caching** for nested content
3. **Low-level caching** for engagement scores, stats
4. **Solid Cache** for distributed caching

### Search Implementation

Consider adding full-text search early (Phase 1):
- **SQLite FTS5** for single-server
- **Meilisearch** for advanced features

### Real-time Updates

Use **Turbo Streams** for:
- Comment threads
- Vote counts
- Reading progress
- Notification badges

### Image Pipeline

```ruby
# app/models/concerns/has_optimized_images.rb
module HasOptimizedImages
  extend ActiveSupport::Concern
  
  included do
    has_one_attached :image do |attachable|
      attachable.variant :thumb, resize_to_limit: [400, 400]
      attachable.variant :medium, resize_to_limit: [800, 800]
      attachable.variant :large, resize_to_limit: [1600, 1600]
      attachable.variant :og, resize_to_fill: [1200, 630]
    end
  end
end
```

---

## Key Concerns to Build

### Sluggable

```ruby
# app/models/concerns/sluggable.rb
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, on: :create
    validates :slug, presence: true, uniqueness: { scope: slug_scope }
  end

  class_methods do
    def slug_scope
      nil # Override in model
    end
  end

  private

  def generate_slug
    return if slug.present?
    
    base_slug = slug_source.parameterize
    self.slug = base_slug
    
    counter = 1
    while self.class.exists?(slug: slug)
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end

  def slug_source
    title # Override in model if different
  end
end
```

### Publishable

```ruby
# app/models/concerns/publishable.rb
module Publishable
  extend ActiveSupport::Concern

  included do
    enum :status, { draft: "draft", scheduled: "scheduled", published: "published", archived: "archived" }
    
    scope :visible, -> { where(status: [:published]) }
    scope :scheduled_for_publish, -> { scheduled.where("scheduled_at <= ?", Time.current) }
    
    before_save :set_published_at
  end

  def publish!
    update!(status: :published, published_at: Time.current)
  end

  def unpublish!
    update!(status: :draft, published_at: nil)
  end

  def schedule!(time)
    update!(status: :scheduled, scheduled_at: time)
  end

  private

  def set_published_at
    if status_changed?(to: "published") && published_at.blank?
      self.published_at = Time.current
    end
  end
end
```

### Auditable

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create { log_audit(:create) }
    after_update { log_audit(:update) }
    after_destroy { log_audit(:delete) }
  end

  private

  def log_audit(action)
    return unless Current.user

    AuditLog.create!(
      account: Current.account,
      user: Current.user,
      action: action,
      auditable: self,
      changes_made: action == :update ? saved_changes.except(:updated_at) : {},
      ip_address: Current.ip_address,
      user_agent: Current.user_agent,
      request_id: Current.request_id
    )
  end
end
```

### Versionable

```ruby
# app/models/concerns/versionable.rb
module Versionable
  extend ActiveSupport::Concern

  included do
    has_many :versions, -> { order(version_number: :desc) }, 
             class_name: "#{name}Version", 
             foreign_key: "#{name.underscore}_id",
             dependent: :destroy
    
    after_save :create_version, if: :content_changed?
  end

  def current_version
    versions.first&.version_number || 0
  end

  def restore_version!(version_number)
    version = versions.find_by!(version_number: version_number)
    update!(
      title: version.title,
      content: version.content
    )
  end

  private

  def create_version
    versions.create!(
      user: Current.user,
      title: title,
      content: content,
      version_number: current_version + 1
    )
  end

  def content_changed?
    saved_change_to_title? || saved_change_to_content?
  end
end
```

---

## Risk Factors

1. **Email deliverability** - Plan for SPF/DKIM/DMARC early
2. **Scale** - Design for horizontal scaling even if starting single-server
3. **Third-party APIs** - Build resilient embed fetching with fallbacks
4. **Real-time features** - Load test Turbo Streams early
5. **ML features** - Start simple, iterate based on data

---

## Success Metrics

Track these throughout development:

- **Time to first post** (publisher onboarding)
- **Email delivery rate** (>98% target)
- **Open/click rates** (benchmark against industry)
- **Comment engagement** (comments per post)
- **Subscriber growth rate** (week over week)
- **Churn rate** (monthly)
- **Page load time** (<2s target)
- **Core Web Vitals** (all green)

---

## Next Steps

1. **Review and finalize** the data model with your team
2. **Set up the project** with proper development environment
3. **Begin Phase 1** with Publications and Posts
4. **Establish testing patterns** early (model tests, system tests)
5. **Set up CI/CD** for continuous deployment
