class SendScheduledNewslettersJob < ApplicationJob
  queue_as :default

  def perform
    Newsletter.ready_to_send.find_each do |newsletter|
      newsletter.send_newsletter!
    end
  end
end
