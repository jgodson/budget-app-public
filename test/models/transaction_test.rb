require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "should not delete transaction associated with loan payment" do
    transaction = transactions(:rent)
    # Ensure it is associated with a loan payment
    assert_not_nil transaction.loan_payment
    
    assert_no_difference('Transaction.count') do
      transaction.destroy
    end
    
    assert_includes transaction.errors[:base], "Cannot delete a transaction associated with a loan payment. Please delete the loan payment from the Loan Payments page."
  end
end