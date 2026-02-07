# Budget App

A comprehensive personal finance management application built with Ruby on Rails. This application helps you track your budgets, expenses, loans, and financial goals.

## Features

- **Dashboard**: Get an overview of your financial status
- **Budgeting**: Create yearly and monthly budgets for different categories
- **Expense Tracking**: Log and categorize your transactions
- **Loan Management**: Track loans and loan payments
- **Goal Setting**: Set and monitor financial goals
- **Data Import**: Import transactions and budgets from external sources
- **Data Portability**: Export/import full workspace data in a portable package format
- **Reporting**: View monthly financial overviews and analytics

## System Requirements

* Ruby 3.3.0
* Rails 7.1.3
* Docker (or Podman)
* PostgreSQL (via Docker)

## Setup and Installation

### Prerequisites

Make sure you have the following installed:
- Ruby 3.3.0
- Bundler
- Node.js and npm (for JavaScript dependencies)
- Docker (or Podman)

### Quick Start

This project uses a `Makefile` to simplify common development tasks.

1. **Clone the repository**
   ```bash
   git clone https://github.com/jgodson/budget-app-public.git
   cd budget-app
   ```

2. **Setup the project**
   This will install gems, start the database container, and prepare the database.
   ```bash
   make setup
   ```

3. **Seed Data (Optional)**
   Populate the database with realistic sample data (2 years worth).
   ```bash
   make seed
   ```

4. **Set up your personal transaction patterns**
   ```
   cp lib/shared/transaction_category_patterns_example.rb lib/shared/transaction_category_patterns.rb
   cp lib/shared/transaction_skip_patterns_example.rb lib/shared/transaction_skip_patterns.rb
   ```

   Edit these files to match your bank's transaction descriptions and personal preferences.

5. Start the server
   ```
   make start
   ```

6. Access the application at `http://localhost:3000`

   Visit `http://localhost:3000` to see the app.

## Development Commands

| Command | Description |
|---------|-------------|
| `make setup` | Installs dependencies, starts Docker, and prepares the DB. |
| `make start` | Starts the database container and the Rails server. |
| `make seed` | Runs the seed script to generate 2 years of sample data. |
| `make console` | Opens the Rails console. |
| `make test` | Runs the test suite. |
| `make stop` | Stops Docker containers |

## Privacy & Security

**The application itself is secure and handles your financial data locally.** However, if you plan to fork this repository or make it public, please review the [Privacy Guidelines](PRIVACY.md) to understand how to handle sensitive configuration files.

### Transaction Pattern Setup

The application uses pattern matching to automatically categorize imported transactions. You'll need to customize these patterns for your bank and preferences:

1. **Copy the example files**:
   ```bash
   cp lib/shared/transaction_category_patterns_example.rb lib/shared/transaction_category_patterns.rb
   cp lib/shared/transaction_skip_patterns_example.rb lib/shared/transaction_skip_patterns.rb
   ```

2. **Edit the patterns** to match your bank's transaction descriptions:
   - `transaction_category_patterns.rb` - Maps transaction descriptions to categories
   - `transaction_skip_patterns.rb` - Defines transactions to ignore during import

3. **Example pattern**:
   ```ruby
   /starbucks/i => 'Entertainment',
   /grocery store/i => 'Food',
   /gas station/i => 'Travel',
   ```

### Security Best Practices

- Keep your database files (`storage/*.sqlite3`) secure and backed up
- Never share your actual transaction pattern files
- Use environment variables for production database credentials
- Delete imported CSV files after processing

### Docker Setup

Alternatively, you can run the application using Docker:

1. Build the Docker image
   ```
   docker build -t budget-app .
   ```

2. Run the container
   ```
   docker run -p 3000:3000 budget-app
   ```

## Database Structure

The application uses several interconnected models:

- **Categories**: For organizing budgets and transactions
- **Budgets**: Yearly or monthly spending limits for categories
- **Transactions**: Individual expenses or income entries
- **Loans**: Track outstanding debts
- **Loan Payments**: Record payments towards loans
- **Goals**: Set financial savings or spending targets

## Development

### Testing

Run the test suite with:
```
rails test
```

### Debugging

The debug gem is included for development. Use `debugger` in your code to set breakpoints.

### Styling

This application uses Bootstrap 5 for styling. CSS files are processed using SassC.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](LICENSE).

**TL;DR**: You can use, modify, and share this code for personal, educational, or research purposes. Commercial use requires permission.

## Acknowledgements

- [Ruby on Rails](https://rubyonrails.org/)
- [Bootstrap](https://getbootstrap.com/)
- [SQLite](https://sqlite.org/)
