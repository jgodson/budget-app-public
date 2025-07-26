module Shared
  module TransactionCategoryPatterns
    # Define regex patterns and corresponding categories
    # NOTE: These are example patterns. Customize them for your needs.
    CATEGORY_PATTERNS = {
      # Child-related expenses
      /daycare/i => 'Kid Stuff',
      /school/i => 'Kid Stuff',
      /children/i => 'Kid Stuff',
      /playground/i => 'Kid Stuff',
      /toy/i => 'Kid Stuff',

      # Pet expenses
      /veterinary/i => 'Pet Stuff',
      /pet store/i => 'Pet Stuff',
      /pet care/i => 'Pet Stuff',
      /animal hospital/i => 'Pet Stuff',

      # Food and groceries
      /grocery/i => 'Food',
      /supermarket/i => 'Food',
      /food/i => 'Food',
      /market/i => 'Food',

      # Entertainment and dining
      /restaurant/i => 'Entertainment',
      /coffee/i => 'Entertainment',
      /cinema/i => 'Entertainment',
      /theater/i => 'Entertainment',
      /streaming/i => 'Entertainment',
      /subscription/i => 'Entertainment',

      # Personal categories (use generic names)
      /books/i => 'Personal - Member A',
      /office supplies/i => 'Personal - Member A',
      
      /beauty/i => 'Personal - Member B',
      /craft/i => 'Personal - Member B',

      # Transportation
      /gas/i => 'Travel',
      /fuel/i => 'Travel',
      /parking/i => 'Travel',

      # Utilities and services
      /phone/i => 'Cellphone',
      /internet/i => 'Internet',
      /utility/i => 'Utilities',

      # Home maintenance
      /hardware/i => 'Home Maintenance',
      /repair/i => 'Home Maintenance',
    }.freeze
  end
end
