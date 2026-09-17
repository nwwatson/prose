require "csv"

module Imports
  module Substack
    # Reads a Substack export (Settings → Exports → Create new export). The
    # download is a zip containing:
    #
    #   posts.csv                    one row per post (title, audience, dates…)
    #   posts/<post_id>.html         the body of each post
    #   email_list.<publication>.csv the subscriber list
    #
    # A bare subscriber CSV (just the email list) is also accepted. Entries are
    # matched by path suffix, so an export re-zipped inside a folder still works.
    #
    # Nothing is extracted to disk and only those entries are read. Because the
    # zip is user-supplied, entry count and decompressed sizes are capped while
    # reading — an entry's declared size can't be trusted (zip bombs).
    class ExportReader
      class InvalidFile < StandardError; end

      ZIP_MAGIC = "PK\x03\x04".b
      BOM = [ 0xFEFF ].pack("U").freeze
      MAX_ENTRIES = 20_000
      MAX_ENTRY_BYTES = 25.megabytes
      MAX_TOTAL_BYTES = 250.megabytes
      POST_HTML = %r{(?:\A|/)posts/([^/]+)\.html\z}
      POSTS_CSV = %r{(?:\A|/)posts\.csv\z}
      EMAIL_LIST_CSV = %r{(?:\A|/)email_list[^/]*\.csv\z}

      attr_reader :posts, :post_bodies, :subscribers

      def initialize(io)
        @posts = []
        @post_bodies = {}
        @subscribers = []
        @total_bytes = 0

        if zip?(io)
          read_zip(io)
        else
          @subscribers = parse_csv(io.read.to_s, "Subscriber CSV", required_header: "email")
        end
      end

      private

      def zip?(io)
        magic = io.read(4).to_s.b
        io.rewind
        magic == ZIP_MAGIC
      end

      def read_zip(io)
        Zip::File.open_buffer(io) do |zip|
          raise InvalidFile, "Export has too many files" if zip.size > MAX_ENTRIES

          found = false
          zip.each do |entry|
            next unless entry.file?

            case entry.name
            when POSTS_CSV
              found = true
              @posts = parse_csv(read_entry(entry), "posts.csv", required_header: "post_id")
            when EMAIL_LIST_CSV
              found = true
              @subscribers.concat(parse_csv(read_entry(entry), entry.name, required_header: "email"))
            when POST_HTML
              @post_bodies[Regexp.last_match(1)] = read_entry(entry).force_encoding(Encoding::UTF_8).scrub
            end
          end
          raise InvalidFile, "Not a Substack export: no posts.csv or email list found" unless found
        end
      rescue Zip::Error => e
        raise InvalidFile, "Could not read zip file: #{e.message}"
      end

      def read_entry(entry)
        data = +"".b
        entry.get_input_stream do |stream|
          while (chunk = stream.read(64.kilobytes))
            data << chunk
            @total_bytes += chunk.bytesize
            raise InvalidFile, "#{entry.name} is too large" if data.bytesize > MAX_ENTRY_BYTES
            raise InvalidFile, "Export is too large once uncompressed" if @total_bytes > MAX_TOTAL_BYTES
          end
        end
        data
      end

      # Rows as hashes with normalized (downcased, stripped) header names.
      def parse_csv(content, name, required_header:)
        content = content.dup.force_encoding(Encoding::UTF_8).scrub.delete_prefix(BOM)
        table = CSV.parse(content, headers: true, header_converters: ->(header) { header.to_s.strip.downcase })
        raise InvalidFile, "#{name} has no #{required_header} column" unless table.headers.include?(required_header)

        table.map(&:to_h)
      rescue CSV::MalformedCSVError => e
        raise InvalidFile, "Could not parse #{name}: #{e.message}"
      end
    end
  end
end
