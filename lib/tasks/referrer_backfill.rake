namespace :referrer do
  desc "Backfill referrer_domain and UTM columns from existing referrer URLs"
  task backfill: :environment do
    batch_size = 1000
    updated = 0
    total = PostView.where(referrer_domain: nil).where.not(referrer: nil).count

    puts "Backfilling #{total} post views..."

    PostView.where(referrer_domain: nil).where.not(referrer: nil).find_each(batch_size: batch_size) do |view|
      parsed = ReferrerParser.call(view.referrer)
      attrs = parsed.slice(:domain, :utm_source, :utm_medium, :utm_campaign).transform_keys(domain: :referrer_domain)
      view.update_columns(attrs) if attrs.values.any?(&:present?)
      updated += 1
      print "\r  #{updated}/#{total} processed" if (updated % 100).zero?
    end

    puts "\nDone. Updated #{updated} records."
  end
end
