module DataPortability
  class PackageBuilder
    FORMAT = "data_portability_package".freeze
    VERSION = 1

    Result = Struct.new(:payload, :summary, keyword_init: true)

    def initialize(actor: nil)
      @actor = actor
    end

    def call
      data = {
        "categories" => category_rows,
        "transactions" => transaction_rows,
        "budgets" => budget_rows,
        "goals" => goal_rows,
        "loans" => loan_rows,
        "loan_payments" => loan_payment_rows
      }

      summary = data.transform_values(&:size)

      Result.new(
        payload: {
          "format" => FORMAT,
          "version" => VERSION,
          "exported_at" => timestamp(Time.current),
          "source" => {
            "app" => "rails-budget-app",
            "actor" => {
              "id" => @actor&.id
            }
          },
          "data" => data
        },
        summary: summary
      )
    end

    private

    def category_rows
      categories = Category.order(:id).to_a
      categories.sort_by! { |category| [category.parent_category_id.present? ? 1 : 0, category.id] }

      categories.map do |category|
        {
          "legacy_id" => category.id,
          "name" => category.name,
          "category_type" => category.category_type,
          "parent_legacy_id" => category.parent_category_id,
          "created_at" => timestamp(category.created_at),
          "updated_at" => timestamp(category.updated_at)
        }
      end
    end

    def transaction_rows
      Transaction.order(:date, :id)
                 .map do |transaction|
        {
          "legacy_id" => transaction.id,
          "date" => transaction.date&.iso8601,
          "description" => transaction.description,
          "amount" => transaction.amount,
          "category_legacy_id" => transaction.category_id,
          "import_source" => transaction.import_source,
          "created_at" => timestamp(transaction.created_at),
          "updated_at" => timestamp(transaction.updated_at)
        }
      end
    end

    def budget_rows
      Budget.order(:year, :month, :id)
            .map do |budget|
        {
          "legacy_id" => budget.id,
          "category_legacy_id" => budget.category_id,
          "year" => budget.year,
          "month" => budget.month,
          "budgeted_amount" => budget.budgeted_amount,
          "created_at" => timestamp(budget.created_at),
          "updated_at" => timestamp(budget.updated_at)
        }
      end
    end

    def goal_rows
      Goal.order(:id)
          .map do |goal|
        {
          "legacy_id" => goal.id,
          "goal_name" => goal.goal_name,
          "amount" => goal.amount,
          "category_legacy_id" => goal.category_id,
          "archived_at" => timestamp(goal.archived_at),
          "created_at" => timestamp(goal.created_at),
          "updated_at" => timestamp(goal.updated_at)
        }
      end
    end

    def loan_rows
      Loan.order(:id)
          .map do |loan|
        {
          "legacy_id" => loan.id,
          "loan_name" => loan.loan_name,
          "balance" => loan.balance,
          "apr" => loan.apr&.to_s,
          "category_legacy_id" => loan.category_id,
          "created_at" => timestamp(loan.created_at),
          "updated_at" => timestamp(loan.updated_at)
        }
      end
    end

    def loan_payment_rows
      LoanPayment.order(:payment_date, :id)
                 .map do |loan_payment|
        {
          "legacy_id" => loan_payment.id,
          "loan_legacy_id" => loan_payment.loan_id,
          "associated_transaction_legacy_id" => loan_payment.associated_transaction_id,
          "paid_amount" => loan_payment.paid_amount,
          "interest_amount" => loan_payment.interest_amount,
          "payment_date" => loan_payment.payment_date&.iso8601,
          "created_at" => timestamp(loan_payment.created_at),
          "updated_at" => timestamp(loan_payment.updated_at)
        }
      end
    end

    def timestamp(value)
      return nil if value.blank?

      value.utc.iso8601(6)
    end
  end
end
