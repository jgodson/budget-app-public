require "digest"
require "json"

module DataPortability
  class PackageExporter
    Result = Struct.new(:compressed_payload, :summary, :filename, :checksum, keyword_init: true)

    def initialize(actor: nil)
      @actor = actor
    end

    def call
      build_result = PackageBuilder.new(actor: @actor).call
      json_payload = JSON.generate(build_result.payload)
      compressed_payload = PackageCompression.gzip(json_payload)

      Result.new(
        compressed_payload: compressed_payload,
        summary: build_result.summary,
        filename: export_filename,
        checksum: Digest::SHA256.hexdigest(compressed_payload)
      )
    end

    private

    def export_filename
      timestamp = Time.current.utc.strftime("%Y%m%d-%H%M%S")
      "rails-budget-app-export-#{timestamp}.json.gz"
    end
  end
end
