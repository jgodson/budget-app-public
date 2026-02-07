module DataPortability
  class PackageImporter
    class Error < StandardError; end

    SUPPORTED_VERSION = 1
    SUPPORTED_MODES = %w[replace].freeze

    Result = Struct.new(:summary, keyword_init: true)

    def initialize(package_payload:, mode: "replace")
      @package_payload = package_payload
      @mode = mode.to_s
    end

    def call
      validate_mode!

      payload = normalize_payload(@package_payload)
      validate_payload!(payload)

      data = payload.fetch("data", {})
      summary = Hash.new(0)

      ApplicationRecord.transaction do
        clear_workspace_data! if @mode == "replace"

        category_map = import_categories!(rows_for(data, "categories"), summary)
        transaction_map = import_transactions!(rows_for(data, "transactions"), category_map, summary)
        import_budgets!(rows_for(data, "budgets"), category_map, summary)
        import_goals!(rows_for(data, "goals"), category_map, summary)
        loan_map = import_loans!(rows_for(data, "loans"), category_map, summary)
        import_loan_payments!(rows_for(data, "loan_payments"), loan_map, transaction_map, summary)
      end

      Result.new(summary: summary)
    end

    private

    def validate_mode!
      return if SUPPORTED_MODES.include?(@mode)

      raise Error, "Unsupported import mode '#{@mode}'."
    end

    def normalize_payload(payload)
      return payload.deep_stringify_keys if payload.is_a?(Hash)

      raise Error, "Package payload must be a JSON object."
    end

    def validate_payload!(payload)
      raise Error, "Unsupported package format." if payload["format"].to_s != PackageBuilder::FORMAT

      version = payload["version"].to_i
      raise Error, "Unsupported package version '#{payload['version']}'." unless version == SUPPORTED_VERSION
    end

    def rows_for(data, key)
      rows = data[key]
      return [] if rows.blank?
      return rows if rows.is_a?(Array)

      raise Error, "Invalid '#{key}' payload."
    end

    def import_categories!(rows, summary)
      category_map = {}
      remaining = rows.map(&:deep_stringify_keys)

      while remaining.any?
        created_count = 0

        remaining.delete_if do |row|
          legacy_id = integer!(row, "legacy_id")
          parent_legacy_id = integer_or_nil(row["parent_legacy_id"])
          next false if parent_legacy_id.present? && !category_map.key?(parent_legacy_id)

          category = Category.create!(
            name: row["name"].to_s,
            category_type: row["category_type"],
            parent_category: parent_legacy_id.present? ? category_map.fetch(parent_legacy_id) : nil,
            created_at: parse_time(row["created_at"]),
            updated_at: parse_time(row["updated_at"])
          )

          category_map[legacy_id] = category
          created_count += 1
          summary["categories"] += 1
          true
        end

        next if created_count.positive?

        raise Error, "Category parent mapping is invalid."
      end

      category_map
    end

    def import_transactions!(rows, category_map, summary)
      transaction_map = {}

      rows.map(&:deep_stringify_keys).each do |row|
        legacy_id = integer!(row, "legacy_id")
        category = category_map.fetch(integer!(row, "category_legacy_id"))

        transaction = Transaction.create!(
          category: category,
          date: parse_date!(row["date"]),
          description: row["description"],
          amount: integer!(row, "amount"),
          import_source: row["import_source"].presence || "Imported",
          created_at: parse_time(row["created_at"]),
          updated_at: parse_time(row["updated_at"])
        )

        transaction_map[legacy_id] = transaction
        summary["transactions"] += 1
      end

      transaction_map
    end

    def import_budgets!(rows, category_map, summary)
      rows.map(&:deep_stringify_keys).each do |row|
        category = category_map.fetch(integer!(row, "category_legacy_id"))

        Budget.create!(
          category: category,
          year: integer!(row, "year"),
          month: integer_or_nil(row["month"]),
          budgeted_amount: integer!(row, "budgeted_amount"),
          created_at: parse_time(row["created_at"]),
          updated_at: parse_time(row["updated_at"])
        )

        summary["budgets"] += 1
      end
    end

    def import_goals!(rows, category_map, summary)
      rows.map(&:deep_stringify_keys).each do |row|
        category = category_map.fetch(integer!(row, "category_legacy_id"))

        Goal.create!(
          category: category,
          goal_name: row["goal_name"].to_s,
          amount: integer!(row, "amount"),
          archived_at: parse_time(row["archived_at"]),
          created_at: parse_time(row["created_at"]),
          updated_at: parse_time(row["updated_at"])
        )

        summary["goals"] += 1
      end
    end

    def import_loans!(rows, category_map, summary)
      loan_map = {}

      rows.map(&:deep_stringify_keys).each do |row|
        legacy_id = integer!(row, "legacy_id")
        category = category_map.fetch(integer!(row, "category_legacy_id"))

        loan = Loan.create!(
          category: category,
          loan_name: row["loan_name"].to_s,
          balance: integer!(row, "balance"),
          apr: decimal_or_nil(row["apr"]),
          created_at: parse_time(row["created_at"]),
          updated_at: parse_time(row["updated_at"])
        )

        loan_map[legacy_id] = loan
        summary["loans"] += 1
      end

      loan_map
    end

    def import_loan_payments!(rows, loan_map, transaction_map, summary)
      rows.map(&:deep_stringify_keys).each do |row|
        loan = loan_map.fetch(integer!(row, "loan_legacy_id"))
        associated_transaction = transaction_map.fetch(integer!(row, "associated_transaction_legacy_id"))

        LoanPayment.insert_all(
          [
            {
              loan_id: loan.id,
              paid_amount: integer!(row, "paid_amount"),
              interest_amount: integer!(row, "interest_amount"),
              payment_date: parse_date!(row["payment_date"]),
              associated_transaction_id: associated_transaction.id,
              created_at: parse_time(row["created_at"]) || Time.current,
              updated_at: parse_time(row["updated_at"]) || Time.current
            }
          ]
        )

        summary["loan_payments"] += 1
      end
    end

    def clear_workspace_data!
      LoanPayment.delete_all
      Goal.delete_all
      Budget.delete_all
      Loan.delete_all
      Transaction.delete_all
      Category.delete_all
    end

    def integer!(row, key)
      value = row[key]
      raise Error, "Missing required value '#{key}'." if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      raise Error, "Invalid integer for '#{key}'."
    end

    def integer_or_nil(value)
      return nil if value.blank?

      Integer(value)
    rescue ArgumentError, TypeError
      raise Error, "Invalid integer value '#{value}'."
    end

    def decimal_or_nil(value)
      return nil if value.blank?

      BigDecimal(value.to_s)
    rescue ArgumentError
      raise Error, "Invalid decimal value '#{value}'."
    end

    def parse_date!(value)
      raise Error, "Missing required date value." if value.blank?

      Date.iso8601(value.to_s)
    rescue ArgumentError
      raise Error, "Invalid date value '#{value}'."
    end

    def parse_time(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      raise Error, "Invalid timestamp value '#{value}'."
    end
  end
end
