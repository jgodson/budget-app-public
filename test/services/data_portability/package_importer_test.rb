require "json"
require "test_helper"

module DataPortability
  class PackageImporterTest < ActiveSupport::TestCase
    test "imports package and replaces workspace data" do
      payload = PackageBuilder.new.call.payload

      stale_category = Category.create!(name: "Stale Category", category_type: :expense)
      Transaction.create!(category: stale_category, amount: 100, date: Date.current, description: "stale")

      # Compatibility keys may be present in packages from other systems.
      # Legacy app ignores these fields entirely.
      payload["data"]["import_templates"] = "ignored string"
      payload["data"]["categorization_rules"] = { "unexpected" => true }
      payload["data"]["skip_rules"] = 123

      result = PackageImporter.new(
        package_payload: payload,
        mode: "replace"
      ).call

      refute Category.where(name: "Stale Category").exists?

      assert_equal payload.dig("data", "categories").size, Category.count
      assert_equal payload.dig("data", "transactions").size, Transaction.count
      assert_equal payload.dig("data", "budgets").size, Budget.count
      assert_equal payload.dig("data", "goals").size, Goal.count
      assert_equal payload.dig("data", "loans").size, Loan.count
      assert_equal payload.dig("data", "loan_payments").size, LoanPayment.count
      assert_equal 0, result.summary["import_templates"]
      assert_equal 0, result.summary["categorization_rules"]
      assert_equal 0, result.summary["skip_rules"]
    end

    test "rejects unsupported package version" do
      error = assert_raises(PackageImporter::Error) do
        PackageImporter.new(
          package_payload: {
            "format" => PackageBuilder::FORMAT,
            "version" => 99,
            "data" => {}
          },
          mode: "replace"
        ).call
      end

      assert_includes error.message, "Unsupported package version"
    end

    test "round-trips exporter payload and restores equivalent data" do
      parent = Category.create!(name: "Home", category_type: :expense)
      child = Category.create!(name: "Repairs", category_type: :expense, parent_category: parent)
      Transaction.create!(
        category: child,
        amount: 12_345,
        date: Date.current - 3.days,
        description: "Plumbing repair",
        import_source: "Manual"
      )
      Budget.create!(category: child, year: Date.current.year, month: 2, budgeted_amount: 80_000)

      savings_category = Category.create!(name: "Vacation Savings", category_type: :savings)
      Goal.create!(goal_name: "Vacation", amount: 120_000, category: savings_category)

      loan_category = Category.create!(name: "Appliance Debt", category_type: :expense)
      loan = Loan.create!(loan_name: "Appliance Debt", balance: 80_000, category: loan_category, apr: 6.75)
      LoanPayment.create!(loan: loan, paid_amount: 2_000, interest_amount: 300, payment_date: Date.current - 1.day)

      exported = PackageExporter.new.call
      payload = JSON.parse(PackageCompression.gunzip(exported.compressed_payload))
      expected = expected_signatures_from_payload(payload.fetch("data"))

      stale_category = Category.create!(name: "Transient Category", category_type: :expense)
      Transaction.create!(category: stale_category, amount: 99, date: Date.current, description: "Transient")

      result = PackageImporter.new(package_payload: payload, mode: "replace").call

      refute Category.where(name: "Transient Category").exists?
      assert_equal expected[:categories], actual_category_signatures
      assert_equal expected[:transactions], actual_transaction_signatures
      assert_equal expected[:budgets], actual_budget_signatures
      assert_equal expected[:goals], actual_goal_signatures
      assert_equal expected[:loans], actual_loan_signatures
      assert_equal expected[:loan_payments], actual_loan_payment_signatures
      assert_equal 0, result.summary["import_templates"]
      assert_equal 0, result.summary["categorization_rules"]
      assert_equal 0, result.summary["skip_rules"]
    end

    private

    def expected_signatures_from_payload(data)
      category_by_id = data.fetch("categories").index_by { |row| row.fetch("legacy_id") }
      transaction_by_id = data.fetch("transactions").index_by { |row| row.fetch("legacy_id") }
      loan_by_id = data.fetch("loans").index_by { |row| row.fetch("legacy_id") }

      {
        categories: canonical_sort(data.fetch("categories").map do |row|
          parent = category_by_id[row["parent_legacy_id"]]
          [row["name"], row["category_type"], parent&.fetch("name")]
        end),
        transactions: canonical_sort(data.fetch("transactions").map do |row|
          category = category_by_id.fetch(row.fetch("category_legacy_id"))
          transaction_signature_from_payload(row, category)
        end),
        budgets: canonical_sort(data.fetch("budgets").map do |row|
          category = category_by_id.fetch(row.fetch("category_legacy_id"))
          [row["year"], row["month"], row["budgeted_amount"], category["name"]]
        end),
        goals: canonical_sort(data.fetch("goals").map do |row|
          category = category_by_id.fetch(row.fetch("category_legacy_id"))
          [row["goal_name"], row["amount"], category["name"], timestamp_to_epoch(row["archived_at"])]
        end),
        loans: canonical_sort(data.fetch("loans").map do |row|
          category = category_by_id.fetch(row.fetch("category_legacy_id"))
          [row["loan_name"], row["balance"], normalize_decimal(row["apr"]), category["name"]]
        end),
        loan_payments: canonical_sort(data.fetch("loan_payments").map do |row|
          loan = loan_by_id.fetch(row.fetch("loan_legacy_id"))
          transaction = transaction_by_id.fetch(row.fetch("associated_transaction_legacy_id"))
          category = category_by_id.fetch(transaction.fetch("category_legacy_id"))
          [
            loan["loan_name"],
            row["paid_amount"],
            row["interest_amount"],
            row["payment_date"],
            transaction_signature_from_payload(transaction, category)
          ]
        end)
      }
    end

    def actual_category_signatures
      canonical_sort(
        Category.includes(:parent_category)
                .map { |category| [category.name, category.category_type, category.parent_category&.name] }
      )
    end

    def actual_transaction_signatures
      canonical_sort(
        Transaction.includes(:category).map { |transaction| transaction_signature_from_record(transaction) }
      )
    end

    def actual_budget_signatures
      canonical_sort(
        Budget.includes(:category)
              .map { |budget| [budget.year, budget.month, budget.budgeted_amount, budget.category.name] }
      )
    end

    def actual_goal_signatures
      canonical_sort(
        Goal.includes(:category)
            .map { |goal| [goal.goal_name, goal.amount, goal.category.name, goal.archived_at&.to_i] }
      )
    end

    def actual_loan_signatures
      canonical_sort(
        Loan.includes(:category)
            .map { |loan| [loan.loan_name, loan.balance, normalize_decimal(loan.apr), loan.category.name] }
      )
    end

    def actual_loan_payment_signatures
      canonical_sort(
        LoanPayment.includes(:loan, associated_transaction: :category)
                   .map do |payment|
          [
            payment.loan.loan_name,
            payment.paid_amount,
            payment.interest_amount,
            payment.payment_date.iso8601,
            transaction_signature_from_record(payment.associated_transaction)
          ]
        end
      )
    end

    def transaction_signature_from_payload(transaction_row, category_row)
      [
        transaction_row["date"],
        transaction_row["description"].to_s,
        transaction_row["amount"],
        category_row["name"],
        category_row["category_type"],
        transaction_row["import_source"].presence || "Imported"
      ]
    end

    def transaction_signature_from_record(transaction)
      [
        transaction.date&.iso8601,
        transaction.description.to_s,
        transaction.amount,
        transaction.category.name,
        transaction.category.category_type,
        transaction.import_source.to_s.presence || "Imported"
      ]
    end

    def normalize_decimal(value)
      return nil if value.blank?

      BigDecimal(value.to_s).to_s("F")
    end

    def timestamp_to_epoch(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s).to_i
    end

    def canonical_sort(rows)
      rows.sort_by do |row|
        Array(row).flatten.map { |value| value.to_s }.join("\u0000")
      end
    end
  end
end
