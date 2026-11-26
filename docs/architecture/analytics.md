# Analytics

Traffic analytics and analytics range parsing.

## Traffic Analytics
`Admin::TrafficController` provides a dedicated deep-dive traffic page at `/admin/traffic` with referrer domain breakdown, UTM campaign/source/medium tables, and a configurable range selector (7d/30d/90d/all). `PostView` stores `referrer_domain`, `utm_source`, `utm_medium`, and `utm_campaign` extracted at write time by `TrackPostViewJob`. `ReferrerParser.call(referrer)` (`app/services/referrer_parser.rb`) is the single source of referrer-parsing logic (domain, source classification, UTM extraction, truncation, `URI::InvalidURIError` handling) — both `TrackPostViewJob` and the `referrer:backfill` rake task use it; the rake task slices out `domain`/`utm_*` (renaming `domain` to `referrer_domain`) so it doesn't overwrite `source` on existing rows. `ReferrerAnalyticsQuery` provides aggregation methods. Use `rake referrer:backfill` to populate columns from existing referrer URLs.

## Analytics Range Parsing
`AnalyticsRange` (`app/models/analytics_range.rb`) is a value object that resolves a `range` param (e.g. `"7d"`, `"30d"`, `"6mo"`, `"all"`) to a `since` timestamp via `AnalyticsRange::PRESETS`. `AnalyticsRange.parse(param, default:, allowed:)` falls back to `default` when the param isn't in `allowed`. The `Admin::AnalyticsRangeable` concern (`app/controllers/concerns/admin/analytics_rangeable.rb`) adds a memoized `analytics_range(default:, allowed:)` controller helper, used by `Admin::TrafficController`, `Admin::RevenueController` (both `%w[7d 30d 90d all]`, default `"30d"`), and `Admin::GrowthController` (`%w[6mo 12mo 24mo all]`, default `"12mo"`). `Admin::DashboardController` doesn't take a `range` param but uses `AnalyticsRange.new("30d").since` to avoid repeating `30.days.ago`. The `admin/shared/range_selector` partial (`ranges:`, `current:`, `path:` locals) renders the joined-pill range-selector UI shared by the traffic and growth show views.


## Query Objects
Query objects live in `app/queries/` for complex queries (e.g., `PostViewsQuery`, `SubscriberGrowthQuery`, `PostEngagementQuery`, `ReferrerAnalyticsQuery`, `SegmentSubscribersQuery`). A query object lives for one request, so values that other methods derive from (MRR, view and comment counts, new members, cancellations) are memoized per instance, and `NewsletterAnalyticsQuery` reads all four delivery totals with one `pick`. Canceled memberships in a window are `Membership.canceled_since(time)`
