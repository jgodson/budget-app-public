class LoanPayment < ApplicationRecord
  belongs_to :loan
  belongs_to :associated_transaction, class_name: 'Transaction', dependent: :destroy

  before_validation :create_transaction

  validates :paid_amount, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :interest_amount, presence: true, numericality: { only_integer: true }
  validates :payment_date, presence: true

  def paid_amount_dollars
    paid_amount.to_f / 100
  end

  private

  def create_transaction
    self.associated_transaction = Transaction.create!(
      category: loan.category,
      amount: paid_amount,
      date: payment_date,
      description: "Loan payment for #{loan.loan_name}",
    )
  end
end
