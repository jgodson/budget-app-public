require "stringio"
require "zlib"

module DataPortability
  class PackageCompression
    GZIP_MAGIC = "\x1F\x8B".b

    class << self
      def gzip(payload)
        io = StringIO.new("".b)
        writer = Zlib::GzipWriter.new(io)
        writer.write(payload.to_s)
        writer.close
        io.string
      end

      def gunzip(payload)
        return "" if payload.blank?

        binary = payload.dup.force_encoding(Encoding::BINARY)
        return binary unless gzip?(binary)

        Zlib::GzipReader.new(StringIO.new(binary)).read
      end

      def gzip?(payload)
        payload.to_s.start_with?(GZIP_MAGIC)
      end
    end
  end
end
