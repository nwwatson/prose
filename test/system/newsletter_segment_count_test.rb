require "application_system_test_case"

class NewsletterSegmentCountTest < ApplicationSystemTestCase
  setup do
    sign_in_admin
    @segment = segments(:vip_segment)
  end

  test "choosing a segment shows its subscriber count and clearing it hides it" do
    visit new_admin_newsletter_path
    open_settings_drawer

    assert_no_text matching_label
    select @segment.name, from: "newsletter_segment_id"
    assert_segment_count

    select I18n.t("admin.newsletters.editor_panel.all_subscribers"), from: "newsletter_segment_id"
    assert_no_text matching_label
  end

  test "a saved segment's count shows when the editor loads" do
    newsletter = newsletters(:draft_newsletter)
    newsletter.update!(segment: @segment)

    visit edit_admin_newsletter_path(newsletter)
    open_settings_drawer

    assert_segment_count
  end

  private

  def open_settings_drawer
    find("button[data-action='click->editor-drawer#toggle']").click
    assert_no_selector "[data-editor-drawer-target='panel'].translate-x-full", visible: :all
    sleep 0.4 # the panel's 300ms slide: clicks on a moving <option> are dropped
  end

  def assert_segment_count
    within "[data-segment-count-target='output']" do
      assert_text matching_label
      assert_selector "p", exact_text: @segment.subscriber_count.to_s
    end
  end

  def matching_label
    I18n.t("admin.segments.count.matching_subscribers")
  end
end
