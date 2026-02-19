require "test_helper"

class Ai::SystemPromptsTest < ActiveSupport::TestCase
  setup do
    @context = "Title: Test Post\nContent:\nSome test content here."
  end

  test "chat returns non-empty string with context" do
    result = Ai::SystemPrompts.chat(@context)
    assert result.is_a?(String)
    assert result.present?
    assert_includes result, @context
  end

  test "proofread returns non-empty string with context" do
    result = Ai::SystemPrompts.proofread(@context)
    assert result.present?
    assert_includes result, @context
  end

  test "critique returns non-empty string with context" do
    result = Ai::SystemPrompts.critique(@context)
    assert result.present?
    assert_includes result, @context
  end

  test "brainstorm returns non-empty string with context" do
    result = Ai::SystemPrompts.brainstorm(@context)
    assert result.present?
    assert_includes result, @context
  end

  test "seo returns non-empty string with context" do
    result = Ai::SystemPrompts.seo(@context)
    assert result.present?
    assert_includes result, @context
  end

  test "social_media returns non-empty string with context" do
    result = Ai::SystemPrompts.social_media(@context)
    assert result.present?
    assert_includes result, @context
  end

  test "image_prompt returns non-empty string with context" do
    result = Ai::SystemPrompts.image_prompt(@context)
    assert result.present?
    assert_includes result, @context
  end
end
