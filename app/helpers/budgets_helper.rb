module BudgetsHelper
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
