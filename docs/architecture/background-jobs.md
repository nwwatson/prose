# Background Jobs

Solid Queue jobs, recurring tasks and bulk enqueueing.

## Background Jobs
Solid Queue (database-backed). Jobs live flat in `app/jobs/`. Recurring tasks configured in `config/recurring.yml`. **Solid Queue loads only the block named after `Rails.env` when one exists** (it does not merge top-level tasks into it), so tasks every environment needs go under the `default: &default` anchor that each environment block merges with `<<: *default`; production-only tasks sit in the `production:` block beside the merge. A task added at the top level would silently never run in production.

Fan-outs are bulk-enqueued, never one `perform_later` per record: build the instances and call `ActiveJob.perform_all_later` (`ActionMailer.deliver_all_later` for mail), one call per batch (`SendPostNotificationsJob` and `FederatePostJob` use batches of 500, `SendDigestsJob` one per subscriber batch, `WebhookDispatcher` one per event). Bulk enqueueing **skips enqueue callbacks**, so don't add `before_enqueue`/`around_enqueue` behavior to these jobs. Tests assert on batching with `BulkEnqueueHelper#capture_bulk_enqueues`.

`PublishScheduledPostsJob` and `SendScheduledNewslettersJob` rescue per record and report with `Rails.error.report`, so one record that raises can't block the rest of the run (it is retried on the next one).

