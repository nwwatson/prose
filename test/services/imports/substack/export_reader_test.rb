require "test_helper"
require_relative "../../../test_helpers/substack_export_helper"

class Imports::Substack::ExportReaderTest < ActiveSupport::TestCase
  include SubstackExportHelper

  test "reads posts, bodies and subscribers from an export zip" do
    reader = read(substack_export_zip)

    assert_equal 7, reader.posts.size
    assert_equal "101.first-issue", reader.posts.first["post_id"]
    assert_equal %w[101.first-issue 102.paid-deep-dive 103.free-members 104.draft-idea 105.episode-one].sort, reader.post_bodies.keys.sort
    assert_includes reader.post_bodies["102.paid-deep-dive"], "Only for paying readers"
    assert_equal 6, reader.subscribers.size
    assert_equal "Reader.One@Example.com", reader.subscribers.first["email"]
  end

  test "matches entries inside a wrapping folder" do
    reader = read(substack_export_zip(prefix: "export-2024/"))

    assert_equal 7, reader.posts.size
    assert_equal 6, reader.subscribers.size
  end

  test "accepts a bare subscriber csv with a byte order mark" do
    csv = "\xEF\xBB\xBF".b + file_fixture("substack/email_list.example.csv").binread
    reader = read(csv)

    assert_empty reader.posts
    assert_equal 6, reader.subscribers.size
    assert reader.subscribers.first.key?("email")
  end

  test "normalizes header case and whitespace" do
    reader = read(" Email , Created_At\nx@example.com,2024-01-01\n")
    assert_equal({ "email" => "x@example.com", "created_at" => "2024-01-01" }, reader.subscribers.first)
  end

  test "rejects csv without an email column" do
    error = assert_raises(Imports::Substack::ExportReader::InvalidFile) { read("name\nBob\n") }
    assert_match(/no email column/, error.message)
  end

  test "rejects malformed csv" do
    assert_raises(Imports::Substack::ExportReader::InvalidFile) { read(%(email\n"unterminated\n)) }
  end

  test "rejects zips without posts.csv or an email list" do
    zip = Zip::OutputStream.write_buffer { |z| z.put_next_entry("readme.txt"); z.write("hi") }.string
    error = assert_raises(Imports::Substack::ExportReader::InvalidFile) { read(zip) }
    assert_match(/Not a Substack export/, error.message)
  end

  test "rejects corrupt zips" do
    assert_raises(Imports::Substack::ExportReader::InvalidFile) { read("PK\x03\x04garbage".b) }
  end

  test "stops reading entries that decompress beyond the size limit" do
    zip = substack_export_zip(extra: { "posts/999.huge.html" => "a" * 2048 })

    with_limit(:MAX_ENTRY_BYTES, 1024) do
      error = assert_raises(Imports::Substack::ExportReader::InvalidFile) { read(zip) }
      assert_match(/too large/, error.message)
    end
  end

  test "caps the total decompressed size" do
    with_limit(:MAX_TOTAL_BYTES, 256) do
      error = assert_raises(Imports::Substack::ExportReader::InvalidFile) { read(substack_export_zip) }
      assert_match(/too large once uncompressed/, error.message)
    end
  end

  test "caps the number of entries" do
    with_limit(:MAX_ENTRIES, 3) do
      error = assert_raises(Imports::Substack::ExportReader::InvalidFile) { read(substack_export_zip) }
      assert_match(/too many files/, error.message)
    end
  end

  private

  def read(content)
    Imports::Substack::ExportReader.new(StringIO.new(content))
  end

  def with_limit(name, value)
    klass = Imports::Substack::ExportReader
    original = klass.const_get(name)
    klass.send(:remove_const, name)
    klass.const_set(name, value)
    yield
  ensure
    klass.send(:remove_const, name)
    klass.const_set(name, original)
  end
end
