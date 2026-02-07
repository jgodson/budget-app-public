require "json"
require "test_helper"

module DataPortability
  class PackageExporterTest < ActiveSupport::TestCase
    test "builds portable package" do
      result = PackageExporter.new.call

      payload = JSON.parse(PackageCompression.gunzip(result.compressed_payload))
      data = payload.fetch("data")

      assert_equal PackageBuilder::FORMAT, payload["format"]
      assert_equal PackageBuilder::VERSION, payload["version"]
      assert_equal 64, result.checksum.length
      assert_match(/\Arails-budget-app-export-\d{8}-\d{6}\.json\.gz\z/, result.filename)

      assert_equal Category.count, data.fetch("categories").size
      assert_equal Transaction.count, data.fetch("transactions").size
      assert_equal Budget.count, data.fetch("budgets").size
      assert_equal Goal.count, data.fetch("goals").size
      assert_equal Loan.count, data.fetch("loans").size
      assert_equal LoanPayment.count, data.fetch("loan_payments").size
      refute data.key?("import_templates")
      refute data.key?("categorization_rules")
      refute data.key?("skip_rules")
    end
  end
end
