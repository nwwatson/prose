# Absolute-URL options (host, port, protocol) for URLs built outside a request,
# such as in jobs, webhook payloads and emails. Sourced from the Action Mailer
# config, which production sets from APP_HOST.
module AppUrlOptions
  def self.call
    Rails.application.config.action_mailer.default_url_options.presence || { host: "localhost", port: 3000 }
  end
end
