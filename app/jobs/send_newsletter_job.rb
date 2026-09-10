class SendNewsletterJob < ApplicationJob
  queue_as :default

  def perform(newsletter_id)
    newsletter = Newsletter.find(newsletter_id)
    provider = EmailService.provider
    count = 0

    pending_subscribers(newsletter).find_each do |subscriber|
      begin
        newsletter.newsletter_deliveries.create!(subscriber: subscriber, sent_at: Time.current)
      rescue ActiveRecord::RecordNotUnique
        next
      end

      provider.deliver_newsletter(newsletter, subscriber)
      count += 1
    end

    newsletter.mark_sent!(count)
  end

  private

  def pending_subscribers(newsletter)
    newsletter.target_subscribers.where.not(id: newsletter.newsletter_deliveries.select(:subscriber_id))
  end
end
