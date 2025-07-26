class Category < ApplicationRecord
  include CategoryTypes

  has_many :transactions, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :loans, dependent: :destroy
  has_many :subcategories, class_name: 'Category', foreign_key: 'parent_category_id', dependent: :destroy
  belongs_to :parent_category, class_name: 'Category', optional: true

  enum category_type: CATEGORY_TYPES

  validates :name, presence: true, uniqueness: { scope: :parent_category_id }
  validates :category_type, presence: true
  validate :category_type_matches_parent
  validate :no_parent_if_subcategories

  before_save :update_subcategories_type
  before_destroy :no_deletion_if_subcategory

  scope :expenses, -> { where(category_type: CATEGORY_TYPES[:expense]) }
  scope :incomes, -> { where(category_type: CATEGORY_TYPES[:income]) }
  scope :savings, -> { where(category_type: CATEGORY_TYPES[:savings]) }
  scope :base_category, -> { where(parent_category_id: nil) }

  private

  def category_type_matches_parent
    if parent_category && category_type != parent_category.category_type
      errors.add(:category_type, "must be the same as the parent category's type")
    end
  end

  def update_subcategories_type
    subcategories.update_all(category_type: category_type) if category_type_changed?
  end

  def no_parent_if_subcategories
    if parent_category_id.present? && subcategories.exists?
      errors.add(:parent_category_id, "cannot be set if the category has subcategories")
    end
  end

  def no_deletion_if_subcategory
    if subcategories.present?
      errors.add(:base, "cannot delete a category with subcategories")
      throw :abort
    end
  end
end