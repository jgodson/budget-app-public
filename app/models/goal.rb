class Goal < ApplicationRecord
  belongs_to :category

  validates :goal_name, presence: true, uniqueness: { scope: :category_id }
  validates :category_id, presence: true, uniqueness: true
  validate :category_must_be_savings
  validates :amount, presence: true, numericality: { only_integer: true, greater_than: 0 }

  after_update :update_goal_category, if: :saved_change_to_category_id?

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def amount_dollars
    amount.present? ? amount / 100.0 : 0
  end

  def amount_dollars=(value)
    self.amount = (value.to_f * 100.0).round
  end

  def percent_complete
    (total_contributed.to_f / amount.to_f * 100).round(2)
  end

  def complete?
    total_contributed >= amount
  end

  def total_contributed_dollars
    total_contributed / 100.0
  end

  def total_contributed
    category.transactions.sum(:amount)
  end

  def total_contributed_by_year
    category.transactions.group_by { |transaction| transaction.date.year }.transform_values { |transactions| transactions.sum(&:amount) }
  end

  def amount_left
    amount - total_contributed
  end

  def amount_left_dollars
    amount_left / 100.0
  end

  def archive
    update(archived_at: Time.current)
  end

  def unarchive
    update(archived_at: nil)
  end

  def archived?
    archived_at.present?
  end

  private

  def category_must_be_savings
    if category.present? && category.category_type != 'savings'
      errors.add(:category, 'must be an savings category')
    end
  end

  def update_goal_category
    Transaction.where(category:).update_all(category:)
  end
end
  