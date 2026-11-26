# Comments

Comment editing, soft delete and reply notifications.

## Comment Features
Comments belong to `Identity` (not `Subscriber`), allowing both admins and subscribers to comment. One-level threading only. Features:
- **Edit/Delete**: Authors can edit within 15 minutes (`Comment::Editable`). `comments/_comment` renders the hidden edit form only when `comment.editable_by?(current_identity)`, so other readers get no form or CSRF token. Soft delete sets `deleted_at` and replaces body with "[deleted]". Admin hard-delete unchanged.
- **Reply Notifications**: Opt-in via `notify_on_reply` checkbox. `Comment::Notifiable` owns the rule (`#reply_notifiable?`: parent opted in, not deleted, someone else's, confirmed subscriber) and enqueues `CommentReplyNotificationJob` on reply creation; the job checks it again and delivers `CommentMailer#reply_notification` itself (`deliver_now`). Its unsubscribe link carries `Comment#notification_token`, read by `Comment.find_by_notification_token` in `CommentNotificationsController`.

