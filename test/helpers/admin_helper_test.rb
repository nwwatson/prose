require "test_helper"

class AdminHelperTest < ActionView::TestCase
  include AdminHelper

  test "status_badge renders default md padding" do
    html = status_badge("Published", color_class: "bg-green-100 text-green-800")
    assert_includes html, "px-2.5 py-0.5"
    assert_includes html, "bg-green-100 text-green-800"
    assert_includes html, "Published"
    assert_includes html, "<span"
  end

  test "status_badge renders sm padding" do
    html = status_badge("Active", color_class: "bg-green-100 text-green-800", size: :sm)
    assert_includes html, "px-2 py-0.5"
    assert_not_includes html, "px-2.5"
  end

  test "admin_button_classes renders primary variant" do
    classes = admin_button_classes(variant: :primary)
    assert_includes classes, "bg-gray-900"
    assert_includes classes, "text-white"
  end

  test "admin_button_classes renders outline variant" do
    classes = admin_button_classes(variant: :outline)
    assert_includes classes, "bg-white"
    assert_includes classes, "ring-1"
  end

  test "admin_button_classes prepends extra classes" do
    classes = admin_button_classes(variant: :primary, extra: "self-start")
    assert classes.start_with?("self-start")
    assert_includes classes, "bg-gray-900"
  end

  test "admin_input_classes includes placeholder styling" do
    classes = admin_input_classes
    assert_includes classes, "placeholder:text-gray-400"
    assert_includes classes, "block w-full"
  end

  test "admin_input_classes prepends extra classes" do
    classes = admin_input_classes(extra: "font-mono")
    assert classes.start_with?("font-mono")
  end

  test "admin_th_classes returns the shared header cell classes" do
    assert_equal "px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500", admin_th_classes
  end
end
