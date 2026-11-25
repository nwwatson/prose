require "test_helper"
require "ostruct"

class Ai::ImagePromptSuggesterTest < ActiveSupport::TestCase
  setup do
    @post = posts(:published_post)
  end

  test "call returns the stripped chat response content" do
    fake_response = OpenStruct.new(content: "  A vivid landscape at sunset.  ")
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) { |_prompt| fake_response }

    result = stub_client_chat(fake_chat) { Ai::ImagePromptSuggester.new(@post).call }

    assert_equal "A vivid landscape at sunset.", result
  end

  test "call builds the prompt from the post's context" do
    fake_response = OpenStruct.new(content: "A prompt")
    captured_prompt = nil
    fake_chat = Object.new
    fake_chat.define_singleton_method(:ask) do |prompt|
      captured_prompt = prompt
      fake_response
    end

    stub_client_chat(fake_chat) { Ai::ImagePromptSuggester.new(@post).call }

    assert_includes captured_prompt, @post.title
  end
end
