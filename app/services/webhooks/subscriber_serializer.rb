module Webhooks
  class SubscriberSerializer
    def self.call(subscriber)
      {
        id: subscriber.id,
        email: subscriber.email,
        confirmed: subscriber.confirmed?,
        created_at: subscriber.created_at.iso8601
      }
    end
  end
end
