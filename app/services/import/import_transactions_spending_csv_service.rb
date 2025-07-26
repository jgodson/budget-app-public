require 'csv'

module Import
  class ImportTransactionsSpendingCsvService
    EXCLUDED_CATEGORIES = []

    class << self
      def service_for_file?(file, model)
        file_name = File.basename(file.original_filename)
        file_name.match?(/Budget (\d{4}) - Spending\.csv/) && model == Transaction
      end
    end

    def initialize(file)
      @file = file
    end

    def preview
      file_name = File.basename(@file.original_filename)
      file_match = file_name.match(/Budget (\d{4}) - Spending\.csv/)

      unless file_match
        raise Errors::InvalidFileError, "File does not match expected format. Expected format: Budget YYYY - Spending.csv"
      end
      
      year = file_match[1].to_i

      csv_text = File.read(@file.path)
      csv_lines = csv_text.lines
      csv_lines.shift(1) # Drop the first row (header)
      csv_text = csv_lines.join

      csv = CSV.parse(csv_text, headers: true)
      date_indexes = csv.headers.each_index.select { |i| csv.headers[i] == "Date" }
      description_indexes = csv.headers.each_index.select { |i| csv.headers[i] == "Description" }
      category_indexes = csv.headers.each_index.select { |i| csv.headers[i] == "Category" }
      amount_indexes = csv.headers.each_index.select { |i| csv.headers[i] == "Value" }

      preview_data = {
        items: [],
        new_categories: []
      }

      csv.each_with_index do |row, index|
        (0..11).each do |month_index|
          date = row.fields[date_indexes[month_index]]
          description = row.fields[description_indexes[month_index]]
          category_name = row.fields[category_indexes[month_index]]
          amount = row.fields[amount_indexes[month_index]]
          amount = amount ? (amount.gsub(/[^\d\.]/, '').to_f * 100).round : 0 # Convert to cents

          next if category_name.nil? || category_name.strip.empty?
          next if EXCLUDED_CATEGORIES.include?(category_name)

          category = Category.find_or_initialize_by(
            name: category_name, 
            category_type: CategoryTypes::CATEGORY_TYPES[:expense]
          )

          # Ensure date is not nil and is a valid day of the month
          next if date.nil? || date.strip.empty? || date.to_i.zero?

          unless preview_data[:new_categories].any? { |c| c.name == category.name }
            preview_data[:new_categories] << category if category.new_record?
          end

          month = month_index + 1

          transaction = {
            category:,
            date: Date.new(year, month, date.to_i),
            description:,
            amount:,
            status: determine_status(category, Date.new(year, month, date.to_i), amount),
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