require "application_system_test_case"

class ShareButtonsTest < ApplicationSystemTestCase
  test "share buttons link to the correct platform intents with the post url and title encoded" do
    post = posts(:published_post)
    visit post_path(post, slug: post.slug)

    encoded_url = ERB::Util.url_encode(post_url(post))
    encoded_title = ERB::Util.url_encode(post.title)

    within ".share-buttons" do
      assert_selector "a[href^='https://twitter.com/intent/tweet?url=#{encoded_url}&text=#{encoded_title}']"
      assert_selector "a[href^='https://www.linkedin.com/sharing/share-offsite/?url=#{encoded_url}']"
      assert_selector "a[href^='https://www.facebook.com/sharer/sharer.php?u=#{encoded_url}']"
      assert_selector "a[href^='mailto:?subject=#{encoded_title}&body=#{encoded_url}']"
    end
  end

  test "copy link button and copy feedback are present, with feedback hidden by default" do
    post = posts(:published_post)
    visit post_path(post, slug: post.slug)

    within ".share-buttons" do
      assert_selector "button[aria-label='Copy link']", visible: :visible
      assert_selector ".share-buttons__copy-feedback", visible: :hidden, text: "Copied!"
    end
  end

  test "native share button is only revealed when the Web Share API is available" do
    post = posts(:published_post)
    visit post_path(post, slug: post.slug)

    within ".share-buttons" do
      supports_native_share = evaluate_script("typeof navigator.share === 'function'")
      assert_selector "button[data-action='share#native']", visible: supports_native_share ? :visible : :hidden
    end
  end
end
