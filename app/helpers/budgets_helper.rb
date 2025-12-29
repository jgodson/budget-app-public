module BudgetsHelper
  def budget_spent_label(budget)
    case budget.category.category_type
    when 'income' then 'Received'
    when 'savings' then 'Saved'
    else 'Spent'
    end
  end

  def budget_spent_color(budget)
    case budget.category.category_type
    when 'income', 'savings' then 'text-success'
    else 'text-danger'
    end
  end

  def budget_remaining_color(budget, remaining)
    is_expense = budget.category.category_type == 'expense'
    
    if is_expense
      remaining >= 0 ? 'text-success' : 'text-danger'
    else
      # Income/Savings: Over budget (remaining <= 0) is good.
      remaining <= 0 ? 'text-success' : 'text-danger'
    end
  end

  def status_class(status)
    case status
    when :new
      'text-bg-success'
    when :duplicate
      'text-bg-warning'
    when :ignored
      'text-bg-secondary'
    else
      'text-bg-secondary'
    end
  end
end
