require "json"
require "test_helper"

class Tools::ImportExportsControllerTest < ActionDispatch::IntegrationTest
  test "shows import export page" do
    get tools_import_export_url

    assert_response :success
    assert_select "h1", text: "Data Portability"
  end

  test "export downloads portable package" do
    post tools_import_export_export_url

    assert_response :success
    assert_equal "application/gzip", response.media_type

    payload = JSON.parse(DataPortability::PackageCompression.gunzip(response.body))
    assert_equal DataPortability::PackageBuilder::FORMAT, payload["format"]
    assert_equal DataPortability::PackageBuilder::VERSION, payload["version"]
    assert payload.dig("data", "categories").is_a?(Array)
    assert payload.dig("data", "transactions").is_a?(Array)
  end

  test "import replaces workspace data from package" do
    post tools_import_export_export_url
    assert_response :success
    exported_package = response.body

    Category.create!(name: "Temporary", category_type: :expense)

    file = Tempfile.new(["portability", ".json.gz"])
    file.binmode
    file.write(exported_package)
    file.rewind

    uploaded_file = Rack::Test::UploadedFile.new(file.path, "application/gzip", true, original_filename: "package.json.gz")

    post tools_import_export_import_url, params: { package: uploaded_file }

    assert_redirected_to tools_import_export_url(year: Date.current.year)
    refute Category.where(name: "Temporary").exists?
  ensure
    file.close!
  end
end
