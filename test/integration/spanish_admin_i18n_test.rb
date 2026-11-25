require "test_helper"

class SpanishAdminI18nTest < ActionDispatch::IntegrationTest
  setup do
    SiteSetting.current.update!(locale: "es")
    sign_in_as(:admin)
  end

  teardown do
    I18n.locale = I18n.default_locale
  end

  test "newsletter settings page renders in Spanish" do
    get edit_admin_newsletter_settings_path

    assert_response :success
    assert_select "title", /\AConfiguración del boletín/
    assert_select "label", text: I18n.t("admin.newsletter_settings.edit.default_template", locale: :es)
    assert_select "input[type=submit][value=?]", I18n.t("admin.newsletter_settings.edit.save_settings", locale: :es)
    assert_includes response.body, "Predeterminada del sistema"
    assert_not_includes response.body, "Email Branding"
    assert_not_includes response.body, "translation_missing"
  end

  test "newsletter page renders in Spanish with relative times" do
    newsletter = newsletters(:sent_newsletter)
    newsletter.update!(sent_at: 2.days.ago)

    get admin_newsletter_path(newsletter)

    assert_response :success
    assert_includes response.body, "Enviado hace 2 días"
    assert_includes response.body, "Volver a boletines"
    assert_includes response.body, "Aperturas"
    assert_not_includes response.body, "translation_missing"
  end

  test "relative times in admin lists read in Spanish" do
    passkey = passkeys(:admin_passkey)
    passkey.update!(last_used_at: 3.days.ago)

    get admin_passkeys_path

    assert_includes response.body, "hace 3 días"
  end

  test "form error headings are pluralized in Spanish" do
    patch admin_profile_path, params: { identity: { name: "", handle: "!" } }

    assert_response :unprocessable_entity
    assert_match(/\d+ errores impidieron que tu perfil se guardara|1 error impidió que tu perfil se guardara/, response.body)
  end

  test "handle availability and its client-side labels are Spanish" do
    get handle_availability_path(handle: "newhandle"), as: :turbo_stream

    assert_includes response.body, "Disponible"
  end
end
