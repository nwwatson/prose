require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "time_ago reads naturally in each locale" do
    travel_to Time.zone.local(2026, 11, 25, 12) do
      assert_equal "2 days ago", time_ago(2.days.ago)
      assert_equal "hace 2 días", I18n.with_locale(:es) { time_ago(2.days.ago) }
      assert_equal "hace alrededor de 1 hora", I18n.with_locale(:es) { time_ago(1.hour.ago) }
    end
  end

  test "time_ago falls back to never without a time" do
    assert_equal "Never", time_ago(nil)
    assert_equal "Nunca", I18n.with_locale(:es) { time_ago(nil) }
    assert_equal "Not yet", time_ago(nil, never: "Not yet")
  end
end
