require "test_helper"

class Post::VersionableTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
    @user = users(:admin)
  end

  test "create_version! creates a new version with correct attributes" do
    assert_difference "PostVersion.count", 1 do
      version = @post.create_version!(user: @user)
      assert_equal @post.title, version.title
      assert_equal @post.subtitle, version.subtitle
      assert_equal @post.body_plain, version.body_plain
      assert_equal 3, version.version_number
    end
  end

  test "create_version_if_needed! creates version when cooldown elapsed" do
    # Backdate existing versions so cooldown has elapsed
    @post.post_versions.update_all(created_at: 10.minutes.ago)

    assert_difference "PostVersion.count", 1 do
      @post.create_version_if_needed!(user: @user)
    end
  end

  test "create_version_if_needed! skips when cooldown not elapsed" do
    @post.post_versions.update_all(created_at: 1.minute.ago)

    assert_no_difference "PostVersion.count" do
      @post.create_version_if_needed!(user: @user)
    end
  end

  test "create_version_if_needed! issues exactly one query within cooldown" do
    @post.post_versions.update_all(created_at: 1.minute.ago)

    query_count = 0
    counter = ->(*, payload) { query_count += 1 unless payload[:sql].match?(/\A(begin|commit)/i) }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      @post.create_version_if_needed!(user: @user)
    end

    assert_equal 1, query_count
  end

  test "create_version_if_needed! creates version when no versions exist" do
    post = posts(:draft_post)
    assert_difference "PostVersion.count", 1 do
      post.create_version_if_needed!(user: @user)
    end
  end

  test "version_cooldown_elapsed? returns true with no versions" do
    post = posts(:draft_post)
    assert post.version_cooldown_elapsed?
  end

  test "version_cooldown_elapsed? returns false within cooldown" do
    @post.post_versions.update_all(created_at: 1.minute.ago)
    assert_not @post.version_cooldown_elapsed?
  end

  test "restore_version! restores post content from version" do
    version = post_versions(:version_one)
    @post.restore_version!(version)
    @post.reload

    assert_equal "Original Title", @post.title
    assert_equal "Original subtitle", @post.subtitle
  end

  test "prune_old_versions! removes excess versions" do
    post = posts(:draft_post)
    (PostVersion::MAX_VERSIONS_PER_POST + 5).times do |i|
      post.post_versions.create!(
        user: @user,
        version_number: i + 1,
        title: "Version #{i + 1}",
        body_plain: "Content #{i + 1}"
      )
    end

    assert_equal PostVersion::MAX_VERSIONS_PER_POST + 5, post.post_versions.count
    post.create_version!(user: @user)
    assert_equal PostVersion::MAX_VERSIONS_PER_POST, post.post_versions.count
  end
end
