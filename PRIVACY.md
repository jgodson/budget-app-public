# Privacy Guidelines for Open Source Contribution

**Important**: The Budget App itself is secure and handles your financial data locally. These guidelines are specifically for developers who want to fork, contribute to, or publish this repository publicly.

## ⚠️ Warning

If you fork this repository or plan to make it public, be aware that certain configuration files may contain personally identifiable information:

### Files That May Contain Personal Information

- **`lib/shared/transaction_category_patterns.rb`** - Your customized merchant patterns may reveal:
  - Geographic location (local business names)
  - Personal shopping habits
  - Family member names (if used as categories)
  - Specific service providers

- **`lib/shared/transaction_skip_patterns.rb`** - May contain location-specific utility companies or services

- **Database files** (`storage/*.sqlite3`) - Contain your actual financial transactions

### Safe Alternatives

This repository includes sanitized example files:
- `lib/shared/transaction_category_patterns.rb` - Generic pattern examples
- `lib/shared/transaction_skip_patterns.rb` - Generic skip patterns

## For Contributors

### If You're Contributing Code

1. **Never commit your personal transaction patterns**
2. **Use generic data** in pull requests and issues
3. **Sanitize logs and debug output** before sharing
4. **Report security issues privately** to the maintainer

### If You're Forking for Public Use

1. **Replace personal patterns** with the provided examples
2. **Review commit history** for any accidentally committed personal data
3. **Consider separate repositiories** with a sanitized public version to avoid commiting sensitive info.

## Application Security

The Budget App follows standard Rails security practices:
- Uses secure cookies and CSRF protection
- Stores data locally (not transmitted to external services)
- Uses environment variables for sensitive configuration
- Includes proper parameter filtering for logs

**Remember**: This is about protecting your personal information when sharing code, not about the application's security itself.
