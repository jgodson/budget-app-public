module CategoriesHelper
  def category_spent_label(category)
    case category.category_type
    when 'income' then 'YTD Income'
    when 'savings' then 'YTD Saved'
    else 'YTD Spent'
    end
  end

  def category_amount_color(category)
    case category.category_type
    when 'income', 'savings' then 'text-success'
    else 'text-danger'
    end
  end
end
