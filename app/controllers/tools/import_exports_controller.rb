require "json"

module Tools
  class ImportExportsController < ApplicationController
    MAX_UPLOAD_BYTES = 25.megabytes

    def show
    end

    def export
      result = DataPortability::PackageExporter.new.call

      send_data result.compressed_payload,
                filename: result.filename,
                type: "application/gzip",
                disposition: "attachment"
    end

    def import
      upload = params[:package]
      if upload.blank?
        redirect_to tools_import_export_path, alert: "Select a package file to import."
        return
      end

      if upload.size.to_i > MAX_UPLOAD_BYTES
        redirect_to tools_import_export_path,
                    alert: "Package file is too large (max #{MAX_UPLOAD_BYTES / 1.megabyte}MB)."
        return
      end

      payload = upload.read
      if payload.blank?
        redirect_to tools_import_export_path, alert: "Package file is empty."
        return
      end

      raw_payload = DataPortability::PackageCompression.gunzip(payload)
      parsed_payload = JSON.parse(raw_payload)

      result = DataPortability::PackageImporter.new(
        package_payload: parsed_payload,
        mode: "replace"
      ).call

      redirect_to tools_import_export_path,
                  notice: "Import completed. Workspace data was replaced from the uploaded package (#{result.summary.values.sum} rows)."
    rescue JSON::ParserError => e
      redirect_to tools_import_export_path, alert: "Invalid JSON package: #{e.message}"
    rescue DataPortability::PackageImporter::Error => e
      redirect_to tools_import_export_path, alert: e.message
    rescue ActiveRecord::RecordInvalid => e
      redirect_to tools_import_export_path, alert: e.record.errors.full_messages.to_sentence
    end
  end
end
