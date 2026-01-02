# frozen_string_literal: true

require "test_helper"

class PublicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = accounts(:one)
    @publication = publications(:one)
  end

  test "should get index" do
    get publications_url
    assert_response :success
    assert_select "h1", "Publications"
  end

  test "should show empty state when no publications" do
    Publication.destroy_all
    get publications_url
    assert_response :success
    assert_select "h3", "No publications"
  end

  test "should get new" do
    get new_publication_url
    assert_response :success
    assert_select "h1", "Create New Publication"
  end

  test "should create publication with valid params" do
    assert_difference("Publication.count") do
      post publications_url, params: {
        publication: {
          name: "Test Newsletter",
          tagline: "A test newsletter",
          description: "This is a test publication",
          account_id: @account.id,
          language: "en",
          timezone: "UTC",
          active: true,
          settings: {
            allow_comments: true,
            require_subscription: false,
            show_author_bio: true,
            email_footer: "Thanks for reading!",
            analytics_code: "GA-123456"
          },
          social_links: {
            twitter: "https://twitter.com/test",
            website: "https://example.com"
          }
        }
      }
    end

    publication = Publication.last
    assert_redirected_to publication_url(publication)
    assert_equal "Test Newsletter", publication.name
    assert_equal "A test newsletter", publication.tagline
    assert_equal "en", publication.language
    assert publication.active?
    assert_equal true, publication.settings["allow_comments"]
    assert_equal "https://twitter.com/test", publication.social_links["twitter"]
  end

  test "should not create publication with invalid params" do
    assert_no_difference("Publication.count") do
      post publications_url, params: {
        publication: {
          name: "", # Invalid - name is required
          account_id: @account.id
        }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".text-red-700", /Name can't be blank/
  end

  test "should show publication" do
    get publication_url(@publication)
    assert_response :success
    assert_select "h1", @publication.name
  end

  test "should get edit" do
    get edit_publication_url(@publication)
    assert_response :success
    assert_select "h1", "Edit Publication"
  end

  test "should update publication with valid params" do
    patch publication_url(@publication), params: {
      publication: {
        name: "Updated Newsletter",
        tagline: "Updated tagline",
        custom_domain: "newsletter.example.com",
        settings: {
          allow_comments: false,
          require_subscription: true
        }
      }
    }

    assert_redirected_to publication_url(@publication)
    @publication.reload
    assert_equal "Updated Newsletter", @publication.name
    assert_equal "Updated tagline", @publication.tagline
    assert_equal "newsletter.example.com", @publication.custom_domain
    assert_equal false, @publication.settings["allow_comments"]
    assert_equal true, @publication.settings["require_subscription"]
  end

  test "should not update publication with invalid params" do
    patch publication_url(@publication), params: {
      publication: {
        name: "", # Invalid
        custom_domain: "invalid-domain" # Invalid format
      }
    }
    assert_response :unprocessable_entity
    assert_select ".text-red-700", /Name can't be blank/

    @publication.reload
    assert_not_equal "", @publication.name
  end

  test "should destroy publication" do
    assert_difference("Publication.count", -1) do
      delete publication_url(@publication)
    end

    assert_redirected_to publications_url
  end

  test "should handle file uploads" do
    logo_file = fixture_file_upload("test.png", "image/png")
    favicon_file = fixture_file_upload("test.png", "image/png")

    assert_difference("Publication.count") do
      post publications_url, params: {
        publication: {
          name: "Test with Images",
          account_id: @account.id,
          logo: logo_file,
          favicon: favicon_file
        }
      }
    end

    publication = Publication.last
    assert publication.logo.attached?
    assert publication.favicon.attached?
  end

  test "should only allow permitted social links and settings" do
    post publications_url, params: {
      publication: {
        name: "Test Settings",
        account_id: @account.id,
        social_links: {
          twitter: "https://twitter.com/test",
          facebook: "", # Empty should be ignored
          linkedin: "https://linkedin.com/in/test"
        },
        settings: {
          allow_comments: "1", # String boolean should be converted
          show_author_bio: "true" # Additional allowed setting
        }
      }
    }

    publication = Publication.last
    assert_equal "https://twitter.com/test", publication.social_links["twitter"]
    assert_equal "", publication.social_links["facebook"]
    assert_equal "https://linkedin.com/in/test", publication.social_links["linkedin"]
    assert_equal "1", publication.settings["allow_comments"]
    assert_equal "true", publication.settings["show_author_bio"]
  end

  test "should handle custom CSS" do
    css_content = ".header { background-color: #f3f4f6; }"

    patch publication_url(@publication), params: {
      publication: {
        custom_css: css_content
      }
    }

    @publication.reload
    assert_equal css_content, @publication.custom_css
  end

  test "should display validation errors for custom domain" do
    patch publication_url(@publication), params: {
      publication: {
        custom_domain: "invalid domain with spaces"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".text-red-700", /must be a valid domain/
  end

  test "should handle timezone and language updates" do
    patch publication_url(@publication), params: {
      publication: {
        timezone: "America/New_York",
        language: "es"
      }
    }

    @publication.reload
    assert_equal "America/New_York", @publication.timezone
    assert_equal "es", @publication.language
  end
end
