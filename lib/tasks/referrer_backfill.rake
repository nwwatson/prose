namespace :referrer do
  desc "Backfill referrer_domain and UTM columns from existing referrer URLs"
  task backfill: :environment do
    batch_size = 1000
    updated = 0
    total = PostView.where(referrer_domain: nil).where.not(referrer: nil).count

    puts "Backfilling #{total} post views..."

    PostView.where(referrer_domain: nil).where.not(referrer: nil).find_each(batch_size: batch_size) do |view|
      attrs = parse_referrer(view.referrer)
      view.update_columns(attrs) if attrs.values.any?(&:present?)
      updated += 1
      print "\r  #{updated}/#{total} processed" if (updated % 100).zero?
    end

    puts "\nDone. Updated #{updated} records."
  end

  def parse_referrer(referrer)
    uri = URI.parse(referrer)
    host = uri.host.to_s.downcase
    domain = host.sub(/\Awww\./, "").truncate(255) if host.present?

    attrs = { referrer_domain: domain }

    if uri.query.present?
      params = URI.decode_www_form(uri.query).to_h
      attrs[:utm_source] = params["utm_source"]&.truncate(255)
      attrs[:utm_medium] = params["utm_medium"]&.truncate(255)
      attrs[:utm_campaign] = params["utm_campaign"]&.truncate(255)
    end

    attrs
  rescue URI::InvalidURIError
    {}
  end
end
