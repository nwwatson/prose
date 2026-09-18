require "test_helper"

class SiteSetting::ActivityPubConfigurationTest < ActiveSupport::TestCase
  setup do
    @setting = SiteSetting.current
  end

  test "federation is off by default with no keys" do
    assert_not @setting.activitypub_enabled?
    assert_nil @setting.activitypub_private_key
  end

  test "enabling federation generates a keypair once" do
    @setting.update!(activitypub_enabled: true)

    pem = @setting.activitypub_public_key
    assert_match(/BEGIN PUBLIC KEY/, pem)
    assert_equal pem, @setting.activitypub_signing_key.public_to_pem

    @setting.update!(activitypub_enabled: false)
    @setting.update!(activitypub_enabled: true)
    assert_equal pem, @setting.reload.activitypub_public_key
  end

  test "the private key is encrypted at rest" do
    @setting.update!(activitypub_enabled: true)
    raw = SiteSetting.connection.select_value("SELECT activitypub_private_key FROM site_settings WHERE id = #{@setting.id}")
    assert_no_match(/PRIVATE KEY/, raw)
  end

  test "username is normalized and validated" do
    @setting.activitypub_username = " @My_Blog "
    assert @setting.valid?
    assert_equal "my_blog", @setting.activitypub_username

    @setting.activitypub_username = "no spaces"
    assert_not @setting.valid?
  end

  test "handle includes the configured host" do
    assert_equal "@blog@#{ActivityPub::Urls.host}", @setting.activitypub_handle
  end
end
