# frozen_string_literal: true

require "test_helper"

class PublishableTest < ActiveSupport::TestCase
  # Create a test model that includes Publishable for testing
  def setup
    @test_class = Class.new(ApplicationRecord) do
      include Publishable

      self.table_name = "posts" # Use existing table for testing

      def title
        "Test Title"
      end
    end

    @account = Account.create!(name: "Test Account")
    @publication = Publication.create!(name: "Test Publication", account: @account)
  end

  test "should have draft status by default" do
    record = @test_class.new(
      title: "Test",
      publication_id: @publication.id
    )
    record.save!

    assert record.draft?
    assert_not record.published?
    assert_not record.visible?
  end

  test "should publish record" do
    record = @test_class.create!(
      title: "Test",
      publication_id: @publication.id
    )

    record.publish!

    assert record.published?
    assert record.visible?
    assert_not_nil record.published_at
  end

  test "should unpublish record" do
    record = @test_class.create!(
      title: "Test",
      publication_id: @publication.id
    )
    record.publish!

    record.unpublish!

    assert record.draft?
    assert_not record.visible?
    assert_nil record.published_at
  end

  test "should schedule record" do
    record = @test_class.create!(
      title: "Test",
      publication_id: @publication.id
    )
    future_time = 1.day.from_now

    record.schedule!(future_time)

    assert record.scheduled?
    assert_equal future_time.to_i, record.scheduled_at.to_i
  end

  test "should set published_at when changing to published status" do
    record = @test_class.new(
      title: "Test",
      publication_id: @publication.id
    )

    freeze_time = Time.current
    travel_to freeze_time do
      record.update!(status: :published)
      assert_equal freeze_time.to_i, record.published_at.to_i
    end
  end

  test "should not override existing published_at when changing to published" do
    original_time = 1.week.ago
    record = @test_class.create!(
      title: "Test",
      publication_id: @publication.id,
      published_at: original_time
    )

    record.update!(status: :published)

    assert_equal original_time.to_i, record.published_at.to_i
  end

  test "visible scope should return published records" do
    draft_record = @test_class.create!(
      title: "Draft",
      publication_id: @publication.id,
      status: :draft
    )

    published_record = @test_class.create!(
      title: "Published",
      publication_id: @publication.id,
      status: :published
    )

    visible_records = @test_class.visible

    assert_includes visible_records, published_record
    assert_not_includes visible_records, draft_record
  end

  test "scheduled_for_publish scope should return scheduled records due for publishing" do
    past_scheduled = @test_class.create!(
      title: "Past Scheduled",
      publication_id: @publication.id,
      status: :scheduled,
      scheduled_at: 1.hour.ago
    )

    future_scheduled = @test_class.create!(
      title: "Future Scheduled",
      publication_id: @publication.id,
      status: :scheduled,
      scheduled_at: 1.hour.from_now
    )

    due_records = @test_class.scheduled_for_publish

    assert_includes due_records, past_scheduled
    assert_not_includes due_records, future_scheduled
  end

  test "should validate status enum values" do
    record = @test_class.new(
      title: "Test",
      publication_id: @publication.id
    )

    assert record.draft?

    record.status = "published"
    assert record.published?

    record.status = "scheduled"
    assert record.scheduled?

    record.status = "archived"
    assert record.archived?
  end

  test "should handle status transitions" do
    record = @test_class.create!(
      title: "Test",
      publication_id: @publication.id
    )

    # Draft -> Scheduled
    record.schedule!(1.day.from_now)
    assert record.scheduled?

    # Scheduled -> Published
    record.publish!
    assert record.published?
    assert_not_nil record.published_at

    # Published -> Archived
    record.update!(status: :archived)
    assert record.archived?

    # Archived -> Draft (unpublish)
    record.unpublish!
    assert record.draft?
    assert_nil record.published_at
  end
end
