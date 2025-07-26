class Transaction < ApplicationRecord
  belongs_to :category
  has_one :loan_payment, foreign_key: 'associated_transaction_id', dependent: :destroy

  validates :category_id, :amount, :date, presence: true
  validate :prevent_edit_if_associated_with_loan_payment, on: :update
  before_destroy :prevent_destroy_if_associated_with_loan_payment
  validates :amount, presence: true, numericality: { only_integer: true }

  def amount_dollars
    amount.present? ? amount / 100.0 : 0
  end

  # Method to get the transaction type from the category
  def transaction_type
    category.category_type
  end

  private

  def prevent_edit_if_associated_with_loan_payment
    if loan_payment.present? && (changed_attributes.keys - ['category_id']).any?
      errors.add(:base, "Cannot edit a transaction associated with a loan payment")
      throw(:abort)
    end
  end

  def prevent_destroy_if_associated_with_loan_payment
    if loan_payment.present?
      errors.add(:base, "Cannot delete a transaction associated with a loan payment")
      throw(:abort)
    end
  end
end