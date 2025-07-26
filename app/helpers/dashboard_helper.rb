module DashboardHelper
  def income_status_class(actual, budgeted)
    return '' if actual == 0 && budgeted == 0
    return 'text-success' if actual >= budgeted
    'text-danger'
  end

  def expense_status_class(actual, budgeted)
    return '' if actual == 0 && budgeted == 0
    return 'text-success' if actual <= budgeted
    'text-danger'
  end
end