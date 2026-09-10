namespace :posts do
  desc "Backfill body_plain for posts created before the column existed"
  task backfill_body_plain: :environment do
    posts = Post.where(body_plain: [ nil, "" ])
    total = posts.count
    updated = 0

    puts "Backfilling #{total} posts..."

    posts.find_each do |post|
      post.update_column(:body_plain, post.content&.to_plain_text.to_s)
      updated += 1
      print "\r  #{updated}/#{total} processed" if (updated % 100).zero?
    end

    puts "\nDone. Updated #{updated} records."
  end
end
