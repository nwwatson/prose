# Prose Development Prompts

## Overview

This document contains a complete list of Claude Code prompts for implementing the Prose newsletter platform, based on the roadmap in `roadmap.md`. Each prompt is designed to:

1. Create a feature branch
2. Implement working code with unit tests
3. Ensure RuboCop compliance
4. Submit a pull request for review
5. Wait for approval before continuing

## Workflow

Each prompt follows this pattern:
```
Create a feature branch for [feature]. Implement [specific requirements]. Include comprehensive tests and ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 1: Core Publishing Foundation (6-8 weeks)

### Sprint 1.1: Publications & Posts (2 weeks)

#### 1.1.1 Publication Model and Core Setup
```
Create a feature branch for publication-model. Implement the Publication model with all fields from the data model including name, tagline, slug, description, custom_domain, custom_css, favicon, logo, header_image, social_links, and settings. Add the Sluggable concern and proper validations. Include comprehensive model tests covering validations, slug generation, and associations. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.1.2 Post Model with Rich Content
```
Create a feature branch for post-model. Implement the Post model with all fields including title, content (ActionText), summary, slug, status enum (draft/scheduled/published/archived), scheduled_at, published_at, meta_title, meta_description, reading_time, and view_count. Add the Publishable and Sluggable concerns. Include comprehensive model tests covering the publishing workflow, slug generation, and content handling. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.1.3 Publication Settings UI
```
Create a feature branch for publication-settings. Implement the PublicationsController with views for creating and editing publications. Create forms for all publication fields including logo/favicon uploads, custom CSS editor, and social links management. Add proper authorization and validation handling. Include controller integration tests and system tests for the complete publication setup flow. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.1.4 Post Creation and Editing Flow
```
Create a feature branch for post-creation. Implement the PostsController with full CRUD operations. Create rich post editor using ActionText with Trix. Add post status management UI with draft/schedule/publish actions. Include post preview functionality. Add comprehensive controller tests and system tests for the complete post creation workflow. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.1.5 Post Listing and Filtering
```
Create a feature branch for post-listing. Implement post index views with filtering by status, search by title/content, and sorting by date/title. Add pagination using Kaminari or built-in pagination. Create admin dashboard showing post statistics. Include comprehensive tests for all filtering and search functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 1.2: Post Versioning & Templates (2 weeks)

#### 1.2.1 Post Versioning System
```
Create a feature branch for post-versioning. Implement the PostVersion model and Versionable concern. Add automatic version creation on post saves with content changes. Create version comparison UI showing diffs between versions. Add version restore functionality. Include comprehensive tests for version creation, comparison, and restoration. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.2.2 Post Templates
```
Create a feature branch for post-templates. Implement the PostTemplate model with template creation, editing, and application to new posts. Create template management UI and template gallery. Add system templates for common post types (Weekly Roundup, Q&A, etc.). Include comprehensive tests for template functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 1.3: Co-authoring & Tags (2 weeks)

#### 1.3.1 Multi-author Support
```
Create a feature branch for post-coauthoring. Implement the PostAuthor join model to support multiple authors per post. Create UI for author selection and management. Add author attribution display in post views. Implement per-author notification settings. Include comprehensive tests for multi-author functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.3.2 Tagging System
```
Create a feature branch for tagging-system. Implement the Tag model with post tagging functionality. Create tag management UI with creation, editing, and deletion. Add post tagging interface with autocomplete. Implement tag-based filtering and tag pages on public site. Include comprehensive tests for all tagging functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 1.4: Series, Footnotes & Embeds (2 weeks)

#### 1.4.1 Post Series
```
Create a feature branch for post-series. Implement the Series model with series creation and management. Add UI for assigning posts to series with ordering. Create series navigation on post pages and series listing pages. Include comprehensive tests for series functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.4.2 Footnotes and Embeds
```
Create a feature branch for footnotes-embeds. Implement the Footnote and Embed models. Add footnote insertion in the rich text editor with margin/inline/endnote display options. Implement oEmbed integration for Twitter, YouTube, etc. with caching. Add syntax highlighting for code blocks using Prism.js. Include comprehensive tests for footnotes and embeds. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 1.4.3 Pinned Posts
```
Create a feature branch for pinned-posts. Add pinning functionality to posts with pinned_at timestamp. Implement pinned posts display on publication homepage and in listings. Add pin/unpin controls in admin interface. Include comprehensive tests for pinned post functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 2: Subscriber Management (4-5 weeks)

### Sprint 2.1: Core Subscriber System (2 weeks)

#### 2.1.1 Subscriber Model and Signup
```
Create a feature branch for subscriber-core. Implement the Subscriber model with email, status, confirmed_at, and subscription flow. Create double opt-in confirmation system with email verification. Add unsubscribe handling with SuppressionEntry model. Include comprehensive tests for subscription flow and email confirmation. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 2.1.2 Subscriber Management UI
```
Create a feature branch for subscriber-management. Implement SubscribersController with listing, search, and filtering functionality. Create subscriber detail views with subscription history. Add manual subscriber addition and CSV import/export features. Include comprehensive controller tests and system tests for subscriber management. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 2.2: Subscriber Tags & Notes (1.5 weeks)

#### 2.2.1 Subscriber Tagging
```
Create a feature branch for subscriber-tags. Implement SubscriberTagDefinition and SubscriberTag models. Create tag management UI with creation, editing, and bulk tagging interface. Add tag-based filtering for subscriber lists. Include comprehensive tests for subscriber tagging functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 2.2.2 Subscriber Notes
```
Create a feature branch for subscriber-notes. Implement the SubscriberNote model with notes UI on subscriber detail pages. Add note creation, editing, and deletion. Implement pinned notes feature. Include comprehensive tests for subscriber notes functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 2.3: Email Preferences & Bulk Actions (1.5 weeks)

#### 2.3.1 Email Preferences
```
Create a feature branch for email-preferences. Implement the EmailPreference model with subscriber preference management UI. Add digest frequency options and section-based preferences. Create subscriber-facing preference center. Include comprehensive tests for preference management. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 2.3.2 Bulk Operations
```
Create a feature branch for bulk-operations. Implement bulk action framework for subscribers including bulk tagging, deletion, and export. Create selection UI with filters and batch processing. Add progress tracking for bulk operations. Include comprehensive tests for all bulk operations. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 3: Email Delivery Enhancement (4-5 weeks)

### Sprint 3.1: Email Campaign System (2 weeks)

#### 3.1.1 Email Campaign Models
```
Create a feature branch for email-campaigns. Implement EmailCampaign, EmailDelivery, and EmailClick models. Create campaign creation UI with preview text and plain text editors. Add audience targeting (all, free, paid, tagged subscribers). Include comprehensive tests for campaign models and associations. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 3.1.2 Email Queue and Delivery
```
Create a feature branch for email-delivery. Implement email queue processing using Solid Queue with campaign scheduling. Add delivery status tracking and failed delivery handling. Create email delivery jobs with proper error handling and retries. Include comprehensive tests for email delivery pipeline. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 3.2: Email Analytics & Optimization (2 weeks)

#### 3.2.1 Email Tracking
```
Create a feature branch for email-tracking. Implement open tracking with pixel insertion and click tracking with link rewriting. Create campaign stats dashboard with open/click rates and engagement metrics. Add per-subscriber engagement tracking. Include comprehensive tests for tracking functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 3.2.2 Resend Campaigns and Optimization
```
Create a feature branch for email-optimization. Implement resend to non-openers feature with different subject lines. Add open time histogram collection for send time optimization insights. Create A/B testing framework for subject lines. Include comprehensive tests for optimization features. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 3.3: Email Performance & Templates (1 week)

#### 3.3.1 Email Template System
```
Create a feature branch for email-templates. Implement email template compilation optimization with caching. Create mobile-responsive email templates with dark mode support. Add email preview rendering system. Include comprehensive tests for template rendering and optimization. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 4: Comments & Community (5-6 weeks)

### Sprint 4.1: Threaded Comments (2 weeks)

#### 4.1.1 Comment Model and Threading
```
Create a feature branch for threaded-comments. Implement the Comment model with self-referential parent for threading. Create comment submission UI with nested reply functionality. Add real-time comment updates using Turbo Streams. Include subscriber-only comments toggle. Add comprehensive tests for comment threading and real-time updates. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 4.1.2 Comment Management
```
Create a feature branch for comment-management. Add comment editing and deletion for comment authors. Implement author highlighting for post authors. Create comment management UI for publication owners. Include comprehensive tests for comment management functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 4.2: Comment Moderation & Voting (2 weeks)

#### 4.2.1 Comment Moderation
```
Create a feature branch for comment-moderation. Implement moderation queue UI with approve/reject workflow. Add basic spam detection and comment flagging. Create moderation dashboard with pending comments. Include comprehensive tests for moderation functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 4.2.2 Comment Voting
```
Create a feature branch for comment-voting. Implement the CommentVote model with upvote/downvote functionality. Create voting UI with vote count display and sort by votes option. Add comment pinning for moderators. Include comprehensive tests for voting functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 4.3: Comment Notifications & Discussion Posts (1.5 weeks)

#### 4.3.1 Comment Notifications
```
Create a feature branch for comment-notifications. Implement the CommentNotification model with email notifications for replies and author notifications. Create notification preferences UI. Add notification queue processing. Include comprehensive tests for notification system. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 4.3.2 Discussion Posts
```
Create a feature branch for discussion-posts. Implement discussion post type with discussion-specific UI and featured discussions. Create discussion-focused layouts and templates. Include comprehensive tests for discussion functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 4.4: Polls & Surveys (1 week)

#### 4.4.1 Interactive Polls
```
Create a feature branch for polls-surveys. Implement Poll, PollOption, and PollResponse models. Create poll creation in post editor with single/multiple choice options. Add results display with anonymous vs tracked responses. Implement poll closing/expiration. Include comprehensive tests for poll functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 5: Reader Experience (3-4 weeks)

### Sprint 5.1: Bookmarks & Reading History (1.5 weeks)

#### 5.1.1 Bookmark System
```
Create a feature branch for bookmarks. Implement the Bookmark model with save for later functionality. Create bookmarks list page with organization options. Add bookmark management UI. Include comprehensive tests for bookmark functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

#### 5.1.2 Reading History
```
Create a feature branch for reading-history. Implement ReadingHistoryEntry model with post view tracking. Add reading progress tracking and continue reading feature. Create "already read" indicators in post listings. Include comprehensive tests for reading history functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 5.2: Highlights & Annotations (1.5 weeks)

#### 5.2.1 Text Highlighting
```
Create a feature branch for text-highlights. Implement the Highlight model with text selection highlighting functionality. Create highlight colors and annotation notes. Add highlights list page and export functionality. Include comprehensive tests for highlighting system. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 5.3: Accessibility (1 week)

#### 5.3.1 Accessibility Features
```
Create a feature branch for accessibility. Implement alt text prompts and requirements for image uploads. Add keyboard navigation improvements, skip links, and ARIA labels. Create font size controls and high contrast mode. Conduct screen reader testing and implement fixes. Include comprehensive accessibility tests. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 6: Analytics & Intelligence (2-3 weeks)

### Sprint 6.1: Engagement Scoring (1 week)

#### 6.1.1 Engagement Analytics
```
Create a feature branch for engagement-scoring. Implement engagement score algorithm and background job for score calculation. Create engagement score display and subscriber segmentation by engagement level. Add engagement trends over time dashboard. Include comprehensive tests for engagement scoring. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 6.2: Cohort Analysis (1 week)

#### 6.2.1 Cohort Analytics
```
Create a feature branch for cohort-analysis. Implement CohortSnapshot model with snapshot generation job. Create cohort retention charts and comparison tools. Add cohort data export functionality. Include comprehensive tests for cohort analysis. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 6.3: ML Send Time Optimization (1 week)

#### 6.3.1 Send Time Intelligence
```
Create a feature branch for send-time-optimization. Implement open time data collection and time distribution model. Create optimal send time prediction per subscriber. Add A/B testing for send time effectiveness and insights dashboard. Include comprehensive tests for ML features. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 7: Community Features (2-3 weeks)

### Sprint 7.1: Community Directory (1.5 weeks)

#### 7.1.1 Community Profiles
```
Create a feature branch for community-directory. Implement CommunityProfile model with profile setup flow. Create directory listing page with search and filter functionality. Add profile visibility controls and interest-based matching. Include comprehensive tests for community directory. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 7.2: External Integrations (1.5 weeks)

#### 7.2.1 Webhook Integrations
```
Create a feature branch for webhook-integrations. Implement Integration model with Discord and Slack webhook support. Create webhook event system and integration management UI. Add integration health monitoring. Include comprehensive tests for webhook functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Phase 8: SEO & Security (3-4 weeks)

### Sprint 8.1: SEO Features (1.5 weeks)

#### 8.1.1 SEO Optimization
```
Create a feature branch for seo-features. Implement meta title/description fields and OG image management. Add Twitter Card support and SocialCard model. Create canonical URL handling and noindex controls. Implement sitemap generation job and controller. Add Schema.org structured data and robots.txt management. Include comprehensive tests for SEO features. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 8.2: Two-Factor Authentication (1 week)

#### 8.2.1 2FA Security
```
Create a feature branch for two-factor-auth. Implement TwoFactorCredential model with TOTP support (Google Authenticator). Create backup code generation and 2FA setup flow. Add 2FA verification on login and recovery flow. Include comprehensive tests for 2FA functionality. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Sprint 8.3: Audit Logs & Rate Limiting (1.5 weeks)

#### 8.3.1 Security Monitoring
```
Create a feature branch for security-monitoring. Implement AuditLog model with Auditable concern. Create audit log viewer with filtering and search. Implement RateLimitRecord model with rate limiting middleware. Add per-action rate limits and IP blocking functionality. Create rate limit dashboard. Include comprehensive tests for security features. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Shared Concerns Implementation

### Core Concerns Setup
```
Create a feature branch for shared-concerns. Implement the core concerns from the roadmap: HasPublicId, Sluggable, Publishable, Auditable, and Versionable. Create concern tests and documentation. Add these concerns to the appropriate models. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

### Image Pipeline
```
Create a feature branch for image-pipeline. Implement HasOptimizedImages concern with Active Storage variants for different image sizes. Add image optimization and resizing functionality. Create image upload UI with drag-and-drop and preview. Include comprehensive tests for image processing. Ensure RuboCop compliance. Submit a PR when complete and prompt me for review.
```

---

## Development Guidelines

### Branch Naming Convention
- Feature branches: `feature/[sprint-number]-[feature-name]` (e.g., `feature/1.1.1-publication-model`)
- Bug fixes: `fix/[issue-description]`
- Hotfixes: `hotfix/[issue-description]`

### PR Requirements
1. All tests must pass
2. RuboCop must pass with zero offenses
3. Code coverage must not decrease
4. Include migration files if database changes are made
5. Update documentation if public APIs change

### Testing Requirements
- Model tests for all validations, associations, and business logic
- Controller integration tests for all endpoints
- System tests for critical user flows
- Service/form object tests where applicable

### Code Quality Checks
```bash
# Run before submitting PR
bin/rails test
bundle exec rubocop
```

### Review Process
1. Claude Code submits PR with detailed description
2. Human reviews the PR and running application
3. Human approves/requests changes
4. Claude Code addresses feedback if needed
5. Human merges PR
6. Claude Code moves to next prompt

### Deployment Notes
- Each feature should be deployable independently
- Use feature flags for incomplete features
- Database migrations should be backward compatible
- Test in staging environment before production

---

## Getting Started

1. Start with Phase 1, Sprint 1.1, Task 1.1.1
2. Follow the prompts in order unless dependencies allow parallel work
3. Review each PR thoroughly before approving
4. Test features in the running application
5. Provide feedback for improvements

The estimated timeline is 6-9 months for complete implementation, assuming 1-2 developers working consistently through these prompts.