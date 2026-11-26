require "test_helper"

class AdminSharedPartialsTest < ActionView::TestCase
  test "panel renders a heading and the block as its body" do
    render(layout: "admin/shared/panel", locals: { title: "Sources", wrapper_class: "mt-8", data: { controller: "chart" } }) { "Body text" }

    assert_select "div.bg-white.shadow.rounded-lg.mt-8[data-controller=chart]" do
      assert_select "h2.mb-4", text: "Sources"
    end
    assert_includes rendered, "Body text"
  end

  test "panel puts an action beside the heading" do
    render(layout: "admin/shared/panel", locals: { title: "Sources", action: link_to("Details", "/details") }) { "" }

    assert_select "div.flex.items-center.justify-between.mb-4" do
      assert_select "h2:not(.mb-4)", text: "Sources"
      assert_select "a[href='/details']", text: "Details"
    end
  end

  test "panel stacks the action on narrow screens when asked" do
    render(layout: "admin/shared/panel", locals: { title: "Views", action: "Range", stack: true }) { "" }

    assert_select "div.flex-col.gap-4.mb-6.sm\\:flex-row", text: /Range/
  end

  test "count table renders a header row and one row per entry" do
    render "admin/shared/count_table", headers: %w[Domain Views], rows: { "google.com" => 3, "bing.com" => 1 }, empty: "Nothing yet"

    assert_select "th.text-left", text: "Domain"
    assert_select "th.text-right", text: "Views"
    assert_select "tbody tr", 2
    assert_select "tbody tr:first-child td.text-gray-900", text: "google.com"
    assert_select "tbody tr:first-child td.text-right", text: "3"
    assert_not_includes rendered, "Nothing yet"
  end

  test "count table renders HTML cells and extra count columns" do
    render "admin/shared/count_table", headers: %w[Post Views Loves], rows: [ [ link_to("Hello", "/p"), 5, 2 ] ], empty: "None"

    assert_select "td a[href='/p']", text: "Hello"
    assert_select "td.text-right", 2
  end

  test "count table shows the empty text when there are no rows" do
    render "admin/shared/count_table", headers: %w[Domain Views], rows: {}, empty: "Nothing yet"

    assert_select "table", 0
    assert_select "p", text: "Nothing yet"
  end

  test "bar list scales bars to the largest count" do
    render "admin/shared/bar_list", counts: { "google" => 4, "direct" => 1 }, empty: "None"

    assert_select "div.bg-blue-600[style*='width: 100.0%']"
    assert_select "div.bg-blue-600[style*='width: 25.0%']"
  end

  test "bar list honours a limit" do
    render "admin/shared/bar_list", counts: { "a" => 3, "b" => 2, "c" => 1 }, limit: 2, empty: "None"

    assert_select "div.bg-blue-600", 2
    assert_not_includes rendered, ">c<"
  end

  test "bar list shows the empty text when there are no counts" do
    render "admin/shared/bar_list", counts: {}, empty: "No traffic"

    assert_select "div.bg-blue-600", 0
    assert_select "p", text: "No traffic"
  end

  test "stat card takes wrapper and value classes" do
    render "admin/shared/stat_card", label: "Top source", value: "google", wrapper_class: "col-span-2", value_class: "capitalize", note: "Post title"

    assert_select "div.bg-white.col-span-2" do
      assert_select "div.text-2xl.capitalize", text: "google"
      assert_select "div.text-xs.truncate", text: "Post title"
    end
  end
end
