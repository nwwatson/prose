namespace :prose do
  desc "Generate all required secrets for production deployment"
  task :generate_secrets do
    require "securerandom"

    secrets = {
      "SECRET_KEY_BASE" => SecureRandom.hex(64),
      "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY" => SecureRandom.alphanumeric(32),
      "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY" => SecureRandom.alphanumeric(32),
      "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" => SecureRandom.alphanumeric(32)
    }

    puts "\n=== Prose Production Secrets ===\n\n"
    puts "Add these to your .kamal/.env file or password manager."
    puts "IMPORTANT: Keep these safe — if lost, encrypted data becomes unrecoverable.\n\n"
    secrets.each { |key, value| puts "#{key}=#{value}" }
    puts ""
  end
end
