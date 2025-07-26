require 'csv'
require 'shared/transaction_category_patterns'
require 'shared/transaction_skip_patterns'

module Import
  class ImportTransactionsBmoMcService
    include Shared::TransactionCategoryPatterns
    include Shared::TransactionSkipPatterns

    class << self
      def service_for_file?(file, model)
        file_name = File.basename(file.original_filename)
        file_name.match?(/statement.*\.csv/) && model == Transaction
      end
    end

    def initialize(file)
      @file = file
    end

    def preview
      lines = File.readlines(@file.path).drop(2).join

      # Read CSV data into an array of hashes
      csv_data = CSV.parse(lines, headers: true)

      # Sort CSV data by 'Posting Date'
      sorted_csv_data = csv_data.sort_by { |row| Date.parse(row['Posting Date']).to_time }

      preview_data = {
        items: [],
        new_categories: []
      }

      sorted_csv_data.each_with_index do |row, index|
        date = Date.parse(row['Posting Date'])
        description = row['Description']
        amount = (row['Transaction Amount'].to_f * 100).round # Convert to cents

        # Determine whether to skip the row
        next if SKIP_PATTERNS.any? { |pattern| description.match?(pattern) }

        # Assign category based on regex patterns
        category_name = CATEGORY_PATTERNS.find { |pattern, _category| description.match?(pattern) }
        category_name = category_name ? category_name[1] : 'Other'

        category = Category.find_or_initialize_by(
          name: category_name,
          category_type: CategoryTypes::CATEGORY_TYPES[:expense],
        )

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

    private
    
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