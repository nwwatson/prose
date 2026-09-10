require "test_helper"

class FutureValidatorTest < ActiveSupport::TestCase
  class FutureModel
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :happens_at, :datetime

    validates :happens_at, future: true
  end

  test "accepts a future time" do
    model = FutureModel.new(happens_at: 1.hour.from_now)
    assert model.valid?
  end

  test "rejects a past time" do
    model = FutureModel.new(happens_at: 1.hour.ago)
    assert_not model.valid?
    assert_includes model.errors[:happens_at], "must be in the future"
  end

  test "rejects the current time" do
    model = FutureModel.new(happens_at: Time.current)
    assert_not model.valid?
    assert_includes model.errors[:happens_at], "must be in the future"
  end

  test "skips validation when value is blank" do
    model = FutureModel.new(happens_at: nil)
    assert model.valid?
  end
end
