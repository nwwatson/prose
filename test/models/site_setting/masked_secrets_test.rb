require "test_helper"

class SiteSetting::MaskedSecretsTest < ActiveSupport::TestCase
  setup do
    @setting = SiteSetting.current
  end

  test "assign_attributes_ignoring_mask drops secret attributes set to the mask" do
    @setting.update!(claude_api_key: "sk-ant-original")

    @setting.assign_attributes_ignoring_mask("claude_api_key" => SiteSetting::MaskedSecrets::MASK, "site_name" => "New Name")

    assert_equal "sk-ant-original", @setting.claude_api_key
    assert_equal "New Name", @setting.site_name
  end

  test "assign_attributes_ignoring_mask clears a secret attribute set to blank" do
    @setting.update!(claude_api_key: "sk-ant-original")

    @setting.assign_attributes_ignoring_mask("claude_api_key" => "")

    assert_equal "", @setting.claude_api_key
  end

  test "assign_attributes_ignoring_mask stores a real value" do
    @setting.assign_attributes_ignoring_mask("claude_api_key" => "sk-ant-new-value")

    assert_equal "sk-ant-new-value", @setting.claude_api_key
  end

  test "assign_attributes_ignoring_mask leaves non-secret attributes untouched by mask filtering" do
    @setting.assign_attributes_ignoring_mask("site_name" => SiteSetting::MaskedSecrets::MASK)

    assert_equal SiteSetting::MaskedSecrets::MASK, @setting.site_name
  end

  test "masked_value_for returns the mask when the secret is present" do
    @setting.update!(claude_api_key: "sk-ant-original")

    assert_equal SiteSetting::MaskedSecrets::MASK, @setting.masked_value_for(:claude_api_key)
  end

  test "masked_value_for returns an empty string when the secret is blank" do
    @setting.update!(claude_api_key: nil)

    assert_equal "", @setting.masked_value_for(:claude_api_key)
  end
end
