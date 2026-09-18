require "application_system_test_case"

class ReadingListTest < ApplicationSystemTestCase
  test "anonymous readers save posts to localStorage and see them on the reading list page" do
    post = posts(:design_post)
    visit root_path

    button = find("button.bookmark-btn[data-bookmark-post-id-value='#{post.id}']")
    assert_equal "false", button["aria-pressed"]
    button.click

    assert_selector "button.bookmark-btn--saved[data-bookmark-post-id-value='#{post.id}'][aria-pressed='true']"
    assert_equal [ post.id ], stored_ids

    find(".masthead__actions a[href='#{reading_list_path}']").click

    within "turbo-frame#reading_list_posts" do
      assert_selector ".post-card__title", text: post.title
      assert_selector ".post-card", count: 1
    end
    assert_selector ".subscribe-cta"
  end

  test "un-saving updates every button for that post and empties the list" do
    post = posts(:published_post)
    visit post_path(post, slug: post.slug)

    find("button.bookmark-btn[data-bookmark-post-id-value='#{post.id}']").click
    assert_equal [ post.id ], stored_ids
    find("button.bookmark-btn--saved[data-bookmark-post-id-value='#{post.id}']").click

    assert_no_selector "button.bookmark-btn--saved"
    assert_empty stored_ids

    visit reading_list_path
    assert_selector ".empty-state__text", text: I18n.t("reading_list.show.empty")
  end

  test "signing in merges the device's list into the account, and toggles persist server-side" do
    subscriber = subscribers(:with_token)
    identity = subscriber.identity
    saved = posts(:design_post)

    visit root_path
    find("button.bookmark-btn[data-bookmark-post-id-value='#{saved.id}']").click
    assert_equal [ saved.id ], stored_ids

    subscriber.generate_auth_token!
    visit subscriber_session_path(token: subscriber.auth_token)

    assert_selector "button.bookmark-btn--saved[data-bookmark-post-id-value='#{saved.id}']"
    assert_eventually { identity.reading_list_post_ids == [ saved.id ] }
    assert_empty stored_ids

    other = posts(:published_post)
    find("button.bookmark-btn[data-bookmark-post-id-value='#{other.id}']", match: :first).click
    assert_eventually { identity.reading_list_post_ids == [ other.id, saved.id ] }

    visit reading_list_path
    assert_selector ".post-card", count: 2
    assert_no_selector ".subscribe-cta"
  end

  private
    def stored_ids
      JSON.parse(page.evaluate_script("localStorage.getItem('reading_list')") || "[]")
    end

    def assert_eventually(timeout: Capybara.default_max_wait_time)
      deadline = Time.current + timeout
      until yield
        flunk "condition not met within #{timeout}s" if Time.current > deadline
        sleep 0.1
      end
    end
end
