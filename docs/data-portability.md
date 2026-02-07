# Data Portability

`rails-budget-app` supports synchronous export/import of workspace data using the app package schema.

## Access

Use **Tools -> Import / Export** in the app sidebar.

## Package Format

- `format: data_portability_package`
- `version: 1`
- File type: `.json` or `.json.gz`

Export includes:

- Categories (with parent/subcategory relationships)
- Transactions
- Budgets
- Goals
- Loans
- Loan payments

Compatibility keys are tolerated on import and ignored when present:

- `import_templates`
- `categorization_rules`
- `skip_rules`

## Export

Export is generated synchronously and downloaded immediately from the UI.

## Import

Import is processed synchronously in the request cycle.

Current mode:

- `replace` (default and only mode)

`replace` clears existing workspace data and imports package data.

## Example Package

Use `docs/examples/data-portability-sample.json.gz` for a ready-to-import sample in development.
