RubyLLM.configure do |config|
  # API keys are configured at request time from SiteSetting
  # to support user-configurable keys stored with Active Record Encryption.
  # See Ai::Configurable concern for the configure_ruby_llm! method.
  config.default_model = "claude-sonnet-5-5"
end
