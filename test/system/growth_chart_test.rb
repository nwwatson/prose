require "application_system_test_case"

class GrowthChartTest < ApplicationSystemTestCase
  setup do
    sign_in_admin
  end

  test "clicking Cumulative moves the active state to that button" do
    visit admin_growth_path

    monthly_btn = find("[data-growth-chart-target='monthlyBtn']")
    cumulative_btn = find("[data-growth-chart-target='cumulativeBtn']")

    assert monthly_btn[:class].include?("bg-blue-600")
    assert_not cumulative_btn[:class].include?("bg-blue-600")

    cumulative_btn.click

    assert_not find("[data-growth-chart-target='monthlyBtn']")[:class].include?("bg-blue-600")
    assert find("[data-growth-chart-target='cumulativeBtn']")[:class].include?("bg-blue-600")
  end
end
