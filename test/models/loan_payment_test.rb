require "test_helper"

class LoanPaymentTest < ActiveSupport::TestCase
  test "creates transaction with import_source Loan Payment" do
    loan = loans(:car_loan)
    payment = LoanPayment.create!(
      loan: loan,
      paid_amount: 10000,
      interest_amount: 100,
      payment_date: Date.today
    )
    
    transaction = payment.associated_transaction
    assert_equal "Loan Payment", transaction.import_source
  end
end