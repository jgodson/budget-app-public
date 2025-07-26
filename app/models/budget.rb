class Budget < ApplicationRecord
  belongs_to :category

  validates :category_id, :budgeted_amount, :year, presence: true
  validates :month, inclusion: { in: 1..12, allow_nil: true }
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :unique_category_year_month_combination
  validates :budgeted_amount, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scope to get yearly budgets
  scope :yearly, -> { where(month: nil) }

  # Scope to get monthly budgets
  scope :monthly, -> { where.not(month: nil) }

  attr_accessor :budgeted_amount_dollars

  def budgeted_amount_dollars
    budgeted_amount.present? ? budgeted_amount / 100.0 : 0
  end

  private

  def unique_category_year_month_combination
    if Budget.where(category_id: category_id, year: year, month: month).where.not(id: id).exists?
      errors.add(:base, "Duplicate budget entry for the same category, year, and month")
    end
  end
end