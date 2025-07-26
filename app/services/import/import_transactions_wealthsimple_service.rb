require 'csv'
require 'shared/transaction_category_patterns'
require 'shared/transaction_skip_patterns'

module Import
  class ImportTransactionsWealthsimpleService
    include Shared::TransactionCategoryPatterns
    include Shared::TransactionSkipPatterns

    class << self
      def service_for_file?(file, model)
        file_name = File.basename(file.original_filename)
        file_name.match?(/transactions.*\.csv/i) && model == Transaction
      end
    end

    def initialize(file)
      @file = file
    end
    
    def preview
      csv_data = CSV.read(@file.path, headers: true)
    
      preview_data = {
        items: [],
        new_categories: []
      }
    
      skipped_rows = []
    
      csv_data.each_with_index do |row, index|
        date = safe_parse_date(row['Date'])
        unless date
          skipped_rows << { reason: "Invalid date", row: row.to_h }
          next
        end
    
        description = row['Description']
        amount = parse_amount(row['Amount'])
    
        if SKIP_PATTERNS.any? { |pattern| description.match?(pattern) }
          skipped_rows << { reason: "Matched skip pattern", row: row.to_h }
          next
        end

        # Categorize
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
  
    if skipped_rows.any?
      Rails.logger.info("[ImportTransactionsWealthsimpleService] Skipped #{skipped_rows.count} row(s)")
      skipped_rows.each { |entry| Rails.logger.debug("Skipped row: #{entry[:reason]}: #{entry[:row]}") }
    end
  
    preview_data
  end

  private

  def safe_parse_date(date_str)
    Date.parse(date_str)
  rescue ArgumentError
    nil
  end

  def parse_amount(amount_str)
    return 0 unless amount_str

    # Fix unicode minus sign and remove any non-numeric characters
    cleaned = amount_str.tr("−", "-").gsub(/[^\d\.\-]/, '')
    amount = cleaned.to_f
    # Make purchases positive, refunds negative (invert)
    (-amount * 100).round
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
