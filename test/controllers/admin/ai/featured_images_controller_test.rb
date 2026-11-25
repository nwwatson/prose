require "test_helper"
require "ostruct"

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
    SiteSetting.current.update!(image_model: "gpt-image-2.6-sunburst", openai_api_key: nil)
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

  test "suggest_prompt renders the suggested prompt on success" do
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |_prompt| OpenStruct.new(content: "A vivid landscape at sunset.") }

    stub_client_chat(fake_chat) do
      post suggest_prompt_admin_post_ai_featured_image_path(@post), as: :turbo_stream
    end

    assert_response :success
    assert_includes response.body, "A vivid landscape at sunset."
  end

  test "suggest_prompt renders an error when the LLM call fails" do
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |_prompt| raise RubyLLM::Error.new("boom") }

    stub_client_chat(fake_chat) do
      post suggest_prompt_admin_post_ai_featured_image_path(@post), as: :turbo_stream
    end

    assert_response :success
    assert_includes response.body, "boom"
  end
end
