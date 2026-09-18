# Builds a Substack export zip in memory from test/fixtures/files/substack.
module SubstackExportHelper
  SUBSTACK_FIXTURE_DIR = Rails.root.join("test/fixtures/files/substack")

  def substack_export_zip(prefix: "", except: [], extra: {})
    buffer = Zip::OutputStream.write_buffer do |zip|
      Dir.chdir(SUBSTACK_FIXTURE_DIR) do
        Dir.glob("**/*").select { |path| File.file?(path) }.sort.each do |path|
          next if except.include?(path)

          zip.put_next_entry("#{prefix}#{path}")
          zip.write(File.binread(path))
        end
      end
      extra.each do |path, content|
        zip.put_next_entry(path)
        zip.write(content)
      end
    end
    buffer.string
  end
end
