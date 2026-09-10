class EmailService::Base
  def deliver_newsletter(newsletter, subscriber)
    raise NotImplementedError
  end
end
