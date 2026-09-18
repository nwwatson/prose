module Imports
  # Imports posts and subscribers from a Substack export zip (or subscribers
  # from a bare email list CSV). See BaseImporter for the save-once /
  # skip-duplicates contract that applies to posts.
  #
  # Subscribers are created directly rather than through
  # Subscriber.subscribe_or_sign_in!, so no confirmation emails are sent and no
  # subscriber.created webhooks fire. They already opted in on Substack, so they
  # are marked confirmed with their original signup date; "email disabled" rows
  # import as unsubscribed. Paid billing can't move off Substack's Stripe
  # account, so paid and comp subscribers are labelled for follow-up instead.
  class SubstackImporter < BaseImporter
    AUDIENCES = { "everyone" => :public, "only_free" => :members_only, "only_paid" => :paid_only, "founding" => :paid_only }.freeze
    COMP_PLANS = %w[comp gift].freeze
    PAID_LABEL = "Substack paid".freeze
    COMP_LABEL = "Substack comp".freeze
    LABEL_COLORS = { PAID_LABEL => "#16A34A", COMP_LABEL => "#7C3AED" }.freeze
    SUBSCRIBER_BATCH_SIZE = 500

    private

    def import_items
      reader = Substack::ExportReader.new(@io)
      @converter = Substack::ContentConverter.new(downloader: @downloader, site_url: @site_url, warn: method(:warn))

      reader.posts.each { |row| import_item(row["title"].to_s.strip.presence || "Untitled") { import_post(row, reader.post_bodies) } }
      import_subscribers(reader.subscribers)
    end

    def import_post(row, bodies)
      post_id = row["post_id"].to_s
      title = row["title"].to_s.strip.presence || "Untitled"

      return @stats["skipped"] += 1 if row["type"] == "thread"

      body = bodies[post_id]
      if body.nil?
        warn("Skipped \"#{title}\": no post body found in the export")
        return @stats["skipped"] += 1
      end

      slug = post_id.split(".", 2).last.to_s.parameterize.presence || title.parameterize.presence || "substack-#{post_id.to_i}"
      return unless importable_slug?(Post, slug, title)

      warn("#{title}: podcast audio was not imported, only the show notes") if row["type"] == "podcast"
      published_at = parse_time(row["post_date"]) || Time.current
      status = truthy?(row["is_published"]) ? resolve_schedule(:scheduled, published_at) : :draft

      post = Post.new(
        title: title,
        subtitle: row["subtitle"].to_s.squish.presence,
        slug: slug,
        user: @user,
        status: status,
        visibility: AUDIENCES.fetch(row["audience"].to_s, :public),
        published_at: status == :draft ? nil : published_at,
        content: @converter.convert(body, title: title)
      )

      save_item(post, title, "posts_imported")
    end

    # Rows are written in transactions of SUBSCRIBER_BATCH_SIZE: a commit per
    # row is very slow on SQLite for lists with tens of thousands of emails.
    def import_subscribers(rows)
      return if rows.empty?

      existing = Subscriber.pluck(:email).to_set
      rows.each_slice(SUBSCRIBER_BATCH_SIZE) do |batch|
        ActiveRecord::Base.transaction do
          batch.each { |row| import_subscriber(row, existing) }
        end
      end
    end

    def import_subscriber(row, existing)
      email = row["email"].to_s.strip.downcase
      unless email.match?(URI::MailTo::EMAIL_REGEXP)
        warn("Skipped invalid subscriber email \"#{email.truncate(60)}\"") if email.present?
        return @stats["subscribers_skipped"] += 1
      end
      return @stats["subscribers_skipped"] += 1 if existing.include?(email)

      signed_up_at = parse_time(row["created_at"]) || Time.current
      # Resolved before the savepoint so a failing row can't roll back a label
      # that later rows have already memoized.
      label = label_for(row)

      # A savepoint per row: an unexpected failure rolls back only this
      # subscriber, not the surrounding batch of SUBSCRIBER_BATCH_SIZE rows.
      ActiveRecord::Base.transaction(requires_new: true) do
        subscriber = Subscriber.new(
          email: email,
          confirmed_at: signed_up_at,
          unsubscribed_at: truthy?(row["email_disabled"]) ? Time.current : nil,
          created_at: signed_up_at
        )
        subscriber.subscriber_labels << label if label

        if subscriber.save
          existing << email
          @stats["subscribers_imported"] += 1
        else
          warn("Skipped subscriber #{email}: #{subscriber.errors.full_messages.to_sentence}")
          @stats["subscribers_skipped"] += 1
        end
      end
    rescue StandardError => e
      Rails.logger.error("[Imports::SubstackImporter] #{email}: #{e.class}: #{e.message}")
      warn("Skipped subscriber #{email}: #{e.class}: #{e.message.to_s.truncate(200)}")
      @stats["subscribers_skipped"] += 1
    end

    def label_for(row)
      return unless truthy?(row["active_subscription"])

      name = COMP_PLANS.include?(row["plan"].to_s.downcase) ? COMP_LABEL : PAID_LABEL
      @labels ||= {}
      @labels[name] ||= SubscriberLabel.where("LOWER(name) = ?", name.downcase).first ||
        SubscriberLabel.create!(name: name, color: LABEL_COLORS.fetch(name))
    end

    def truthy?(value)
      %w[true 1 yes t].include?(value.to_s.strip.downcase)
    end

    def parse_time(value)
      Time.zone.parse(value.to_s) if value.present?
    rescue ArgumentError
      nil
    end
  end
end
