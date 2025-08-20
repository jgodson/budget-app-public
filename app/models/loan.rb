class Loan < ApplicationRecord
  belongs_to :category
  has_many :loan_payments, dependent: :destroy

  validates :loan_name, presence: true, uniqueness: { scope: :category_id }
  validates :category_id, presence: true, uniqueness: true
  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :category_must_be_expense

  after_update :update_loan_payments_category, if: :saved_change_to_category_id?

  scope :active, -> { where.not(balance: 0) }
  scope :paid_off, -> { where(balance: 0) }

  def paid_off?
    balance == 0
  end

  def balance_dollars
    balance.present? ? balance / 100.0 : 0
  end

  def total_paid_dollars
    total_paid / 100.0
  end

  def total_principal_paid_dollars  
    total_principal_paid / 100.0
  end

  def total_interest_paid_dollars 
    total_interest_paid / 100.0
  end

  def total_paid
    loan_payments.sum(&:paid_amount)
  end

  def total_principal_paid
    loan_payments.sum { |payment| payment.paid_amount - payment.interest_amount }
  end

  def total_interest_paid
    loan_payments.sum(&:interest_amount)
  end

  def payments_by_year
    loan_payments.group_by { |payment| payment.payment_date.year }
  end

  def last_payment
    loan_payments&.last
  end

  def percent_complete
    return 100 if balance == 0

    (total_principal_paid.to_f / (balance.to_f + total_principal_paid.to_f) * 100).round(2)
  end

  private

  def category_must_be_expense
    if category.present? && category.category_type != 'expense'
      errors.add(:category, 'must be an expense category')
    end
  end

  def update_loan_payments_category
    loan_payments.each do |loan_payment|
      loan_payment.associated_transaction.update!(category:)
    end
  end
end
