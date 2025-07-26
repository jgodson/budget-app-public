require 'csv'
require 'shared/transaction_category_patterns'
require 'shared/transaction_skip_patterns'

module Import
  class ImportTransactionsRbcVisaService
    include Shared::TransactionCategoryPatterns
    include Shared::TransactionSkipPatterns

    class << self
      def service_for_file?(file, model)
        file_name = File.basename(file.original_filename)
        file_name.match?(/csv.*\.csv/) && model == Transaction
      end
    end

    def initialize(file)
      @file = file
    end

    def preview
      csv_data = CSV.read(@file.path, headers: true)

      # Sort CSV data by 'Transaction Date'
      sorted_csv_data = csv_data.sort_by { |row| Date.strptime(row['Transaction Date'], '%m/%d/%Y').to_time }

      preview_data = {
        items: [],
        new_categories: []
      }

      sorted_csv_data.each_with_index do |row, index|
        date = Date.strptime(row['Transaction Date'], '%m/%d/%Y')
        description = row['Description 1']
        amount = (row['CAD$'].to_f * 100).round # Convert to cents
        # Reverse negative sign
        amount = -amount

        # Determine whether to skip the row
        next if SKIP_PATTERNS.any? { |pattern| description.match?(pattern) }

        # Assign category based on regex patterns
        category_name = CATEGORY_PATTERNS.find { |pattern, _category| description.match?(pattern) }
        category_name = category_name ? category_name[1] : 'Other'

        category = Category.find_or_initialize_by(name: category_name, category_type: 'expense')

        unless preview_data[:new_categories].any? { |c| c.name == category.name }
          preview_data[:new_categories] << category if category.new_record?
        end

        transaction = {
          category:,
          date:,
          description:,
          amount:,
          status: determine_status(category, date, amount),
          unique_id: index
        }

        preview_data[:items] << transaction
      end

      preview_data
    end

    def determine_status(category, date, amount)
      if amount.zero?
        :ignored
      elsif Transaction.exists?(category:, date:, amount:)
        :duplicate
      elsif Transaction.exists?(category:, date: date.beginning_of_month..date.end_of_month, amount:)
        :potential_duplicate
      else
        :new
      end
    end
  end
end