require "test_helper"

class JobLocaleTest < ActiveJob::TestCase
  include LocaleHelper

  class LocaleProbeJob < ApplicationJob
    cattr_accessor :seen

    def perform = self.class.seen = I18n.locale
  end

  setup { spanish_site! }

  test "jobs run under the site locale" do
    LocaleProbeJob.perform_now

    assert_equal :es, LocaleProbeJob.seen
    assert_equal :en, I18n.locale
  end

  test "the site locale wins over the one the job was enqueued under" do
    perform_enqueued_jobs { I18n.with_locale(:en) { LocaleProbeJob.perform_later } }

    assert_equal :es, LocaleProbeJob.seen
  end

  test "mail delivered later is in the site language" do
    subscriber = subscribers(:confirmed)
    subscriber.generate_auth_token!

    perform_enqueued_jobs { SubscriberMailer.magic_link(subscriber).deliver_later }

    assert_equal "Iniciar sesión en #{SiteSetting.current.site_name}", ActionMailer::Base.deliveries.last.subject
  end

  test "an AI error is reported in the site language" do
    SiteSetting.current.update!(claude_api_key: "test-key")
    chat = Chat.create!(post: posts(:published_post), user: users(:admin), conversation_type: "chat")
    failing_chat = Object.new
    failing_chat.define_singleton_method(:with_instructions) { |_| self }
    failing_chat.define_singleton_method(:add_message) { |**| }
    failing_chat.define_singleton_method(:ask) { |_| raise RubyLLM::Error.new("<boom>") }
    replaced = []

    stub_client_chat(failing_chat) do
      with_singleton_stub(Turbo::StreamsChannel, :broadcast_append_to, ->(*, **) { }) do
        with_singleton_stub(Turbo::StreamsChannel, :broadcast_replace_to, ->(*, **options) { replaced << options[:html] }) do
          AiResponseJob.perform_now(chat.id, "Hello")
        end
      end
    end

    assert_includes replaced.last, I18n.t("flash.admin.ai.error", locale: :es, message: "").strip
    assert_includes replaced.last, "&lt;boom&gt;"
  end
end
