# Emails a post to its mailing lists' subscribers the first time it goes live.
#
# The trigger is the status transition itself (not `publish!`), so the admin
# editor, the REST API, MCP and the scheduled-post job all notify the same way.
# `subscribers_notified_at` is claimed atomically before enqueuing, which keeps
# an unpublish/republish (or a duplicate commit) from emailing anyone twice.
module Post::Notifiable
  extend ActiveSupport::Concern

  included do
    has_many :mailing_list_posts, dependent: :delete_all
    has_many :mailing_lists, through: :mailing_list_posts

    # New posts start on the lists marked "subscribe by default" unless the
    # caller chose lists explicitly (the editor always submits its checkboxes,
    # so unchecking every list there really does mean "email nobody").
    after_initialize :assign_default_mailing_lists, if: -> { new_record? && !@mailing_lists_chosen }
    after_commit :notify_subscribers, on: [ :create, :update ], if: :notify_subscribers?

    # Defined in the included block so they land on Post itself and `super`
    # reaches the association's generated writers.
    def mailing_list_ids=(ids)
      @mailing_lists_chosen = true
      super
    end

    def mailing_lists=(lists)
      @mailing_lists_chosen = true
      super
    end
  end

  # Confirmed subscribers of the post's active lists.
  def notification_recipients
    Subscriber.confirmed.subscribed_to(mailing_lists.active)
  end

  private

  def assign_default_mailing_lists
    self.mailing_lists = MailingList.subscribed_by_default.to_a
  end

  def notify_subscribers?
    saved_change_to_status? && published? && subscribers_notified_at.nil?
  end

  def notify_subscribers
    claimed = Post.where(id: id, subscribers_notified_at: nil).update_all(subscribers_notified_at: Time.current)
    SendPostNotificationsJob.perform_later(id) if claimed == 1
  end
end
