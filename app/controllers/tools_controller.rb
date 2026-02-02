class ToolsController < ApplicationController
  def amortization
    loans = Loan.active.order(:loan_name)
    @loan_options = loans.map do |loan|
      last_payment = loan.loan_payments.order(payment_date: :desc).first
      {
        id: loan.id,
        name: loan.loan_name,
        balance_dollars: loan.balance_dollars,
        last_payment_dollars: last_payment ? (last_payment.paid_amount / 100.0) : 0
      }
    end
  end
end
