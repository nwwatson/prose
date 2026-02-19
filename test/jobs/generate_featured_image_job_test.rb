require "test_helper"

class GenerateFeaturedImageJobTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
    @user = users(:admin)
    SiteSetting.current.update!(gemini_api_key: "test-gemini-key")
  end

  test "can be instantiated" do
    job = GenerateFeaturedImageJob.new
    assert_instance_of GenerateFeaturedImageJob, job
  end

  test "is queued on default queue" do
    assert_equal "default", GenerateFeaturedImageJob.new.queue_name
  end
end
