require 'csv'

module Import
  class ImportTransactionsBudgetCsvService
    EXCLUDED_CATEGORIES = [
      "Car Payments", "Mortgage", "Kid Stuff", "Pet Stuff", "Food & Essentials", "Entertainment",
      "Other", "Travel", "Extra Income", "Total Income", "Total Expenditures", "Leftover/Savings",
      "Monitor Payment",
    ]

    class << self
      def service_for_file?(file, model)
        file_name = File.basename(file.original_filename)
        file_name.match?(/Budget (\d{4}) - Budget\.csv/) && model == Transaction
      end
    end

    def initialize(file)
      @file = file
    end

    def preview
      file_name = File.basename(@file.original_filename)
      file_match = file_name.match(/Budget (\d{4}) - Budget\.csv/)
      
      unless file_match
        raise Errors::InvalidFileError, "File does not match expected format. Expected format: Budget YYYY - Budget.csv"
      end

      year = file_match[1].to_i

      csv_text = File.read(@file.path)
      csv_lines = csv_text.lines
      csv_lines.shift(2) # Drop the first two rows
      csv_text = csv_lines.join

      csv = CSV.parse(csv_text, headers: true)

      preview_data = {
        items: [],
        new_categories: []
      }

      csv.each_with_index do |row, index|
        next if row['Item'].nil? || row['Item'].strip.empty?
        next if EXCLUDED_CATEGORIES.include?(row['Item'])

        category_name = row['Item']

        category = Category.find_or_initialize_by(
          name: category_name, 
          category_type: CategoryTypes::CATEGORY_TYPES[:expense]
        )

        unless preview_data[:new_categories].any? { |c| c.name == category.name }
          preview_data[:new_categories] << category if category.new_record?
        end

        (1..12).each_with_index do |month, month_index|
          month_name = Date::MONTHNAMES[month]
          actual_amount = row[month_name] ? (row[month_name].gsub(/[^\d\.]/, '').to_f * 100).round : 0 # Convert to cents, handle missing data

          transaction = {
            category:,
            date: Date.new(year, month, 1),
            amount: actual_amount,
            status: determine_status(category, Date.new(year, month, 1), actual_amount),
            unique_id: "#{month_index}-#{index}"
          }

          preview_data[:items] << transaction
        end
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