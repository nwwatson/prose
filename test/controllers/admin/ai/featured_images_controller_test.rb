require "test_helper"

class Admin::Ai::FeaturedImagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(:admin)
    @post = posts(:published_post)
    SiteSetting.current.update!(claude_api_key: "test-key", gemini_api_key: "test-gemini-key")
  end

  test "suggest_prompt redirects when image AI not configured" do
    SiteSetting.current.update!(gemini_api_key: nil)
    post suggest_prompt_admin_post_ai_featured_image_path(@post)
    assert_redirected_to edit_admin_settings_path
  end

  test "suggest_prompt redirects when openai model selected without openai key" do
    SiteSetting.current.update!(image_model: "gpt-image-1", openai_api_key: nil)
    post suggest_prompt_admin_post_ai_featured_image_path(@post)
    assert_redirected_to edit_admin_settings_path
  end

  test "suggest_prompt redirects when AI not configured at all" do
    SiteSetting.current.update!(claude_api_key: nil, gemini_api_key: nil)
    post suggest_prompt_admin_post_ai_featured_image_path(@post)
    assert_redirected_to edit_admin_settings_path
  end

  test "create enqueues image generation job" do
    assert_enqueued_with(job: GenerateFeaturedImageJob) do
      post admin_post_ai_featured_image_path(@post),
        params: { prompt: "A beautiful landscape" },
        as: :turbo_stream
    end
    assert_response :success
  end

  test "create rejects blank prompt" do
    post admin_post_ai_featured_image_path(@post),
      params: { prompt: "" }
    assert_response :unprocessable_entity
  end
end
