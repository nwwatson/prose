# Fakes for the two newsletter providers, so delivery tests can make the
# provider accept or reject individual recipients.
module EmailProviderHelper
  # Stands in for `SendGrid::API#client`, covering the one call the adapter
  # makes: `client.mail._("send").post(request_body:)`. `responder` gets the
  # recipient address and returns the HTTP status (or raises, for a network
  # failure).
  class FakeSendgridClient
    Response = Struct.new(:status_code, :body)

    attr_reader :accepted, :attempted

    def initialize(&responder)
      @responder = responder || ->(_to) { 202 }
      @accepted = []
      @attempted = []
    end

    def mail = self
    def _(_name) = self

    def post(request_body:)
      body = request_body.is_a?(String) ? JSON.parse(request_body) : request_body.deep_stringify_keys
      to = body.dig("personalizations", 0, "to", 0, "email")
      @attempted << to
      status = @responder.call(to)
      @accepted << to if status.between?(200, 299)
      Response.new(status.to_s, status.between?(200, 299) ? "" : '{"errors":[{"message":"rejected"}]}')
    end
  end

  # Switches the site to SendGrid and routes `SendGrid::API.new` to `fake`.
  # Yields how many API clients were built.
  def with_fake_sendgrid(fake)
    SiteSetting.current.update!(email_provider: "sendgrid", sendgrid_api_key: "SG.test-key")
    built = 0
    api = Struct.new(:client).new(fake)
    with_singleton_stub(SendGrid::API, :new, ->(**) { built += 1; api }) { yield -> { built } }
  end

  # Makes the test mailer raise for the addresses `reject` returns true for,
  # the way an SMTP server refusing a recipient surfaces from `deliver_now`.
  def with_smtp_rejecting(reject)
    deliveries = ActionMailer::Base.deliveries
    deliver = ->(mail) do
      raise Net::SMTPFatalError.new(nil, message: "550 mailbox unavailable") if Array(mail.to).any? { |to| reject.call(to) }
      deliveries << mail
    end
    with_instance_stub(Mail::TestMailer, :deliver!, deliver) { yield }
  end
end
