module Shared
  module TransactionSkipPatterns
    # Patterns for transactions to skip during import
    # NOTE: These are example patterns. Customize them for your needs.
    SKIP_PATTERNS = [
      /payment received/i,
      /payment - thank you/i,
      /your utility company/i,  # Replace with generic utility reference
      /credit card payment/i,
      /transfer/i,
      /refund/i,
    ].freeze
  end
end
