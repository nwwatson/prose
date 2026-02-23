class EmailService::Base
  def send_email(to:, subject:, html:, text:, headers: {}, metadata: {})
    raise NotImplementedError
  end

  def process_webhook(payload)
    raise NotImplementedError
  end
end
