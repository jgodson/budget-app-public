require "test_helper"

class ImportExportsTurboTest < ActionDispatch::IntegrationTest
  test "export form is marked as turbo disabled" do
    html = ApplicationController.render(template: "tools/import_exports/show", layout: false)
    doc = Nokogiri::HTML.parse(html)
    form = doc.at_css("form[action='#{tools_import_export_export_path}']")

    assert_not_nil form
    assert_equal "false", form["data-turbo"]
  end

  test "export endpoint responds with attachment data" do
    post tools_import_export_export_path

    assert_response :success
    assert_equal "application/gzip", response.media_type
    assert_match(/attachment;/, response.headers["Content-Disposition"])
    assert_match(/rails-budget-app-export-\d{8}-\d{6}\.json\.gz/, response.headers["Content-Disposition"])
    assert_not_empty response.body
  end
end
