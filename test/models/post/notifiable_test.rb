require "test_helper"

class Post::NotifiableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def build_post(**attrs)
    Post.new(title: "Notify me", user: users(:admin), **attrs)
  end

  test "new posts start on the default lists" do
    assert_equal [ mailing_lists(:main) ], build_post.mailing_lists.to_a
  end

  test "explicitly chosen lists are kept, including none" do
    assert_equal [ mailing_lists(:deep_dives) ], build_post(mailing_list_ids: [ "", mailing_lists(:deep_dives).id.to_s ]).mailing_lists.to_a
    assert_equal [ mailing_lists(:deep_dives) ], build_post(mailing_lists: [ mailing_lists(:deep_dives) ]).mailing_lists.to_a
    assert_empty build_post(mailing_list_ids: [ "" ]).mailing_lists
  end

  test "loading an existing post doesn't reassign its lists" do
    assert_equal [ mailing_lists(:main), mailing_lists(:deep_dives) ].sort_by(&:id), Post.find(posts(:design_post).id).mailing_lists.sort_by(&:id)
  end

  test "publishing through a plain status update notifies subscribers once" do
    post = posts(:draft_post)

    freeze_time do
      assert_enqueued_with(job: SendPostNotificationsJob, args: [ post.id ]) do
        post.update!(status: :published, published_at: Time.current)
      end
      assert_equal Time.current, post.reload.subscribers_notified_at
    end

    post.revert_to_draft!
    assert_no_enqueued_jobs(only: SendPostNotificationsJob) { post.publish! }
  end

  test "publish! notifies subscribers" do
    assert_enqueued_with(job: SendPostNotificationsJob, args: [ posts(:scheduled_post).id ]) do
      posts(:scheduled_post).publish!
    end
  end

  test "creating a post as published notifies subscribers" do
    assert_enqueued_jobs 1, only: SendPostNotificationsJob do
      build_post(status: :published, published_at: Time.current).save!
    end
  end

  test "drafts, scheduling and edits to published posts don't notify" do
    assert_no_enqueued_jobs only: SendPostNotificationsJob do
      build_post.save!
      posts(:draft_post).schedule!(1.day.from_now)
      posts(:published_post).update!(title: "Edited")
    end
  end

  test "notification_recipients are confirmed subscribers of the post's active lists" do
    post = posts(:published_post)
    post.update!(mailing_lists: [ mailing_lists(:deep_dives), mailing_lists(:retired) ])

    assert_equal [ subscribers(:confirmed) ], post.notification_recipients.to_a

    post.update!(mailing_lists: [ mailing_lists(:retired) ])
    assert_empty post.notification_recipients
  end
end
