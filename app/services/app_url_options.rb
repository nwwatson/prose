# The one source of absolute-URL options (host, port, protocol) for URLs built
# outside a request: webhook payloads, email images and ActivityPub ids. Sourced
# from the Action Mailer config, which production sets from APP_HOST. A config
# without a protocol gets https whenever the app forces SSL.
module AppUrlOptions
  def self.call
    options = (Rails.application.config.action_mailer.default_url_options || {}).slice(:host, :port, :protocol)
    options = options.reverse_merge(host: "localhost", port: 3000) if options[:host].blank?
    options[:protocol] ||= Rails.application.config.force_ssl ? "https" : "http"
    options
  end
end
