# Model Organization

Where each model concern lives and what it does. The rules that matter across the app (Publishable, Prunable, `dependent: :delete_all`) are summarized in CLAUDE.md.

## Model Organization
Models use **concerns for behavior composition**. Each concern lives in a directory matching the model name:

```
app/models/user.rb                    # class User includes concerns
app/models/user/authenticatable.rb    # module User::Authenticatable (concern)
app/models/user/api_tokenable.rb     # module User::ApiTokenable (concern)
app/models/user/passkey_authenticatable.rb # module User::PasskeyAuthenticatable (WebAuthn passkeys)
app/models/post/discoverable.rb      # module Post::Discoverable (related posts, prev/next)
app/models/post/versionable.rb      # module Post::Versionable (revision history, version cooldown)
app/models/post/revisable.rb       # module Post::Revisable (stamps revised_at on reader-visible changes; coalesces post.updated/fediverse Update jobs)
app/models/post/webhookable.rb      # module Post::Webhookable (fires post.published/updated/deleted/scheduled/unpublished webhook events)
app/models/webhook.rb               # Webhook: outbound webhook subscription (url, events, encrypted signing_secret, auto-disable)
app/models/post/federatable.rb      # module Post::Federatable (fediverse Create/Update/Delete on publish/edit/unpublish/destroy)
app/models/site_setting/activity_pub_configuration.rb # module SiteSetting::ActivityPubConfiguration (federation toggle, username, RSA keypair)
app/models/fediverse_actor.rb       # FediverseActor: cached remote ActivityPub actor (inbox, public key); followed_at marks a follower
app/models/fediverse_like.rb        # FediverseLike: a remote actor's Like of a post
app/models/webhook_delivery.rb      # WebhookDelivery: per-attempt delivery log for a Webhook (pruned to Webhook::DELIVERY_LOG_LIMIT)
app/models/post_version.rb          # PostVersion: full snapshot of post content per version
app/models/reading_list_item.rb     # ReadingListItem: identity ↔ post bookmark (unique per pair, capped at MAX_ITEMS = 500 per identity)
app/models/identity/reading_listable.rb # module Identity::ReadingListable (bookmark!/unbookmark!, reading_list_posts/_post_ids, import_reading_list!)
app/models/concerns/sluggable.rb     # module Sluggable (slugged_from macro: slug generation/uniquifying, used by Post, Page, Category, Tag, MailingList; `to_param: true` puts the slug in URLs — all but MailingList)
app/models/concerns/identity_backed.rb # module IdentityBacked (belongs_to :identity, email validation/normalization, build_identity_if_needed; overridable default_identity_name), included by User and Subscriber
app/models/comment/editable.rb        # module Comment::Editable (15-min edit window, soft delete)
app/models/comment/notifiable.rb      # module Comment::Notifiable (reply notification callbacks)
app/models/page.rb                    # class Page (custom static pages)
app/models/navigation_item.rb        # NavigationItem: header/footer/social menu links (label, url, location enum, position, open_in_new_tab)
app/models/navigation_item/cacheable.rb # module NavigationItem::Cacheable (for_location: all locations in one query, memoized on Current per request)
app/models/navigation_item/social_platform.rb # module NavigationItem::SocialPlatform (infers icon platform from URL host)
app/models/concerns/publishable.rb   # module Publishable — shared `publishes_at` macro (live scope, publish!/schedule!/revert_to_draft!), included by Post, Page, Newsletter
app/models/post/status_transitions.rb # module Post::StatusTransitions (became_published?/became_scheduled?/left_published?/edited_while_published?)
app/models/concerns/prunable.rb      # module Prunable (private prune_to_newest(relation, keep:, destroy:) — "keep newest N" for Export, Webhook deliveries, post versions)
app/validators/future_validator.rb   # FutureValidator: shared "must be in the future" validation used by Publishable
app/validators/hex_color_validator.rb # HexColorValidator: shared `validates :x, hex_color: true` for #RRGGBB colors, used by SiteSetting::DarkTheme, SiteSetting::EmailBranding, SubscriberLabel, Newsletter::Templatable
app/models/currency.rb               # Currency: SYMBOLS/NAMES/CODES, `.symbol`, `.format(cents, code)`, `.options_for_select` — used by MembershipTier#formatted_price and SiteSetting::PaymentConfiguration#currency_symbol/SUPPORTED_CURRENCIES
app/models/site_setting/localization.rb  # module SiteSetting::Localization (i18n)
app/models/identity/handleable.rb    # module Identity::Handleable (handle validation/normalization)
app/models/identity/profileable.rb   # module Identity::Profileable (avatar, bio, social links)
app/models/api_token.rb              # Token generation, digest lookup, revocation
app/models/passkey.rb                # WebAuthn passkey credentials for admin sign-in
app/models/subscriber_label.rb       # Labels for subscriber segmentation (name, color)
app/models/subscriber_labeling.rb    # Join model: subscribers ↔ subscriber_labels
app/models/segment.rb                # Saved subscriber filters (JSON filter_criteria)
app/models/segment/resolvable.rb     # module Segment::Resolvable (resolves criteria to subscribers)
app/models/segment/criteria_builder.rb # module Segment::CriteriaBuilder (flat form attrs ↔ filter_criteria JSON)
app/models/membership_tier.rb       # MembershipTier: paid membership plans (name, price, interval)
app/models/membership_tier/syncable.rb # module MembershipTier::Syncable (syncs to Stripe products/prices)
app/models/membership.rb            # Membership: subscriber ↔ tier link with Stripe subscription state
app/models/subscriber/billable.rb   # module Subscriber::Billable (memberships, paid_member?, stripe_customer_id)
app/models/subscriber/email_preferences.rb # module Subscriber::EmailPreferences (email_frequency enum, digest cursor, signed preferences token)
app/models/mailing_list.rb           # MailingList: subscribable list ("newsletter" to readers) — name, slug, description, frequency, active, subscribe_by_default
app/models/mailing_list_subscription.rb # Join: subscribers ↔ mailing_lists (unique per pair)
app/models/mailing_list_post.rb      # Join: posts ↔ mailing_lists (which lists a post is emailed to)
app/models/subscriber/list_subscribable.rb # module Subscriber::ListSubscribable (default-list signup, selected_mailing_list_ids form writer, subscribed_to scope)
app/models/post/notifiable.rb        # module Post::Notifiable (default lists on new posts, emails lists once on the transition to published)
app/models/post/accessible.rb       # module Post::Accessible (visibility enum, content gating)
app/models/site_setting/payment_configuration.rb # module SiteSetting::PaymentConfiguration (Stripe keys)
```

Keep model files under 200 lines — extract behavior into concerns when they grow.

`publishes_at(column, live_statuses: :published)` is the only definition of `live` (matching status, timestamp not in the future). `Post` passes `live_statuses: %i[published scheduled]`, so a due scheduled post is live before `PublishScheduledPostsJob` reaches it, and declares its own `ready_to_publish` for that job. There is one `Publishable` module — don't add a `Post::Publishable` wrapper, which `include Publishable` in `Post` would silently resolve to.

History-like records that keep only the newest N go through `prune_to_newest` (`Prunable`) with a newest-first relation; it deletes in one statement, so pass `destroy: true` (as `Export` does, to purge its file) when the records have callbacks or attachments.

`has_many` associations whose children have no callbacks, attachments or dependents of their own use `dependent: :delete_all` (`post_tags`, `post_views`, `post_versions`, `reading_list_items`, `fediverse_likes`, `newsletter_deliveries`, `subscriber_labelings`, `webhook_deliveries`), so destroying a parent issues one DELETE per table instead of one per row while holding SQLite's writer. Giving one of those child models a destroy callback, attachment or dependent means switching its parents back to `:destroy`. Don't add a single-column index that a composite index on the same table already starts with.


## SiteSetting Caching
`SiteSetting.current` is memoized on `Current.site_setting` (`app/models/current.rb`) for the lifetime of a request or job — `first_or_create!` only runs once per request instead of on every call. An `after_commit` callback on `SiteSetting` clears the memoized value so an update within the same request is not stale. `SiteHelper` exposes a `site_setting` helper method that views should call instead of `SiteSetting.current` directly. `Newsletter::Templatable#resolved_*` methods accept an optional `site` argument so `email_settings` can pass down a single fetched record rather than re-querying per field.
