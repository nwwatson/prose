# Subscriber Growth Feature

## Summary

A full subscriber growth analytics page accessible from the admin sidebar "Growth" link. Provides monthly/cumulative bar charts, configurable time ranges, post-to-subscriber attribution, and top-posts-by-subscribers insights.

## Key Changes

### Database
- Added `source_post_id` (nullable) to `subscribers` table, referencing `posts`

### Attribution Tracking
- New subscribers signing up from a post's comment form automatically have `source_post_id` set
- Homepage subscriptions (no post context) leave `source_post_id` null
- Existing subscribers are not modified on repeat visits

### Analytics Page (`/admin/growth`)
- **Stat cards:** Total Subscribers, New Subscribers (range), Latest Post Subscribers
- **Bar chart:** Monthly new subscribers or cumulative total, rendered as SVG via Stimulus
- **Time ranges:** 6MO / 12MO / 24MO / ALL toggle with Turbo navigation
- **Top Posts table:** Posts ranked by attributed subscriber count

### Models
- `Subscriber` has `belongs_to :source_post` (optional)
- `Post` has `has_many :attributed_subscribers` (dependent: nullify)

### Query Object
- `SubscriberGrowthQuery` expanded with `growth_by_month`, `cumulative_by_month`, `top_posts_by_subscribers`, `most_recent_post_subscribers`

## Forward-Only Tracking

Attribution tracking is forward-only — existing subscribers will not have `source_post_id` set. The top posts table will populate as new subscribers sign up from post pages.
