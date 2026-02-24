class TocExtractor
  HEADING_SELECTOR = "h2, h3, h4"
  MIN_HEADINGS = 3

  HeadingItem = Data.define(:level, :text, :id)

  def initialize(html)
    @html = html.to_s
  end

  def headings
    @headings ||= extract_headings
  end

  def has_toc?
    headings.size >= MIN_HEADINGS
  end

  def content_with_anchors
    return @html unless has_toc?

    doc = parse_document
    doc.css(HEADING_SELECTOR).each_with_index do |node, index|
      node["id"] = headings[index].id
    end
    doc.inner_html
  end

  private

  def extract_headings
    doc = parse_document
    seen_ids = Hash.new(0)

    doc.css(HEADING_SELECTOR).map do |node|
      level = node.name[1].to_i
      text = node.text.strip
      id = generate_id(text, seen_ids)
      HeadingItem.new(level: level, text: text, id: id)
    end
  end

  def generate_id(text, seen_ids)
    base = text.downcase
      .gsub(/[^a-z0-9\s-]/, "")
      .gsub(/\s+/, "-")
      .gsub(/-+/, "-")
      .gsub(/\A-|-\z/, "")

    base = "heading" if base.blank?

    seen_ids[base] += 1
    seen_ids[base] > 1 ? "#{base}-#{seen_ids[base]}" : base
  end

  def parse_document
    Nokogiri::HTML.fragment(@html)
  end
end
