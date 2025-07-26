require 'csv'

module Import
  class ImportBudgetsBudgetCsvService
    EXCLUDED_CATEGORIES = [
      "Total Income", "Total Expenditures", "Leftover/Savings"
    ]
    INCOME_CATEGORIES = /income/i

    class << self
      def service_for_file?(file, model)
        file_name = File.basename(file.original_filename)
        file_name.match?(/Budget (\d{4}) - Budget\.csv/) && model == Budget
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
        amount = row['Amount'] ? (row['Amount'].gsub(/[^\d\.]/, '').to_f * 100).round : 0 # Convert to cents

        category_type = if INCOME_CATEGORIES.match(category_name)
          CategoryTypes::CATEGORY_TYPES[:income]
        else
          CategoryTypes::CATEGORY_TYPES[:expense]
        end

        category = Category.find_or_initialize_by(
          name: category_name, 
          category_type:,
        )

        unless preview_data[:new_categories].any? { |c| c.name == category.name }
          preview_data[:new_categories] << category if category.new_record?
        end

        budget = {
          category:,
          year:,
          amount:,
          status: determine_status(category, year, amount),
          unique_id: index,
        }

        preview_data[:items] << budget
      end

      preview_data
    end

    private

    def determine_status(category, year, amount)
      if amount.zero?
        :ignored
      elsif Budget.exists?(category:, year:)
        :duplicate
      else
        :new
      end
    end
  end
end