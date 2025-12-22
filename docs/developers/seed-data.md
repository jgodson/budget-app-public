# Seed Data Script

This project includes a utility script to populate the database with realistic sample data for development and testing purposes.

## Usage

The script is located in the `scripts` folder: `./scripts/seed-data.sh`.

```bash
./scripts/seed-data.sh <duration>
```

### Arguments

- `<duration>`: The time range for which to generate data.
  - Use `y` for years (e.g., `2y` for 2 years).
  - Use `m` for months (e.g., `6m` for 6 months).

### Examples

Generate 2 years of data:
```bash
./scripts/seed-data.sh 2y
```

Generate 6 months of data:
```bash
./scripts/seed-data.sh 6m
```

## What it does

1.  **Cleans Database**: It sets `CLEAN=true`, which wipes all existing `Transactions`, `Budgets`, `Loans`, `Goals`, and `Categories` to ensure a fresh state.
2.  **Creates Categories**: Sets up standard Income and Expense categories.
3.  **Creates Loans**: Initializes sample loans (e.g., Car Loan, Student Loan).
4.  **Generates History**: Loops back from the current date for the specified duration to create:
    - Monthly Budgets
    - Income Transactions (Salary, Freelance)
    - Expense Transactions (randomized amounts and categories)
    - Loan Payments (with interest calculations)

## Prerequisites

- The database must be running (e.g., via Docker Compose).
- Gems must be installed (`bundle install`), specifically `faker` is required for data generation.
- The database must be created (`rails db:create db:schema:load`).
