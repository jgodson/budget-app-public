class DashboardController < ApplicationController
  def index
    @selected_year = params[:year]&.to_i || Date.current.year
    @available_years = Transaction.distinct.pluck(:date).map { |date| date.year }.uniq
    @available_years += Budget.select(:year).distinct.pluck(:year)
    @available_years.uniq!.sort!.reverse!

    # Fetch all categories including their subcategories
    @categories = Category.includes(:subcategories).order(:name)

    # Fetch budgets and transactions for the selected year
    @budgets = Budget.where(year: @selected_year).includes(:category)
    @transactions = Transaction.where("strftime('%Y', date) = ?", @selected_year.to_s).includes(:category)

    # Category data
    @category_data = prepare_category_data(@categories, @budgets, @transactions)

    # Goal data
    @active_goals = Goal.active.includes(:category)
    @archived_goals = Goal.archived.includes(:category)
    @goals = @active_goals + @archived_goals

    # Loan data
    @active_loans = Loan.active
    @paid_off_loans = Loan.paid_off
    @loans = @active_loans + @paid_off_loans

    # Calculate Totals
    calculate_totals
  end

  def monthly_overview
    @categories = Category.all
    @income_categories = @categories.select { |c| c.category_type == 'income' && c.parent_category.nil? }
    @expense_categories = @categories.select { |c| c.category_type == 'expense' && c.parent_category.nil? }
    @savings_categories = @categories.select { |c| c.category_type == 'savings' && c.parent_category.nil? }
    
    # Get the year parameter or default to the current year
    @selected_year = params[:year].nil? ? Date.today.year : params[:year].to_i

    # Fetch transactions and budgets for the selected year
    @transactions = Transaction.where("strftime('%Y', date) = ?", @selected_year.to_s).includes(:category)
    @budgets = Budget.where(year: @selected_year).includes(:category)

    # Group transactions by month, then by category_type and category
    @transactions_by_month_and_type = @transactions.group_by { |t| [t.date.strftime("%B"), t.category.category_type] }
    @available_years = Transaction.distinct.pluck(:date).map { |date| date.year }.uniq
    @available_years += Budget.select(:year).distinct.pluck(:year)
    @available_years.uniq!.sort!.reverse!

    # Prepare monthly category summaries
    @monthly_category_summaries = prepare_monthly_category_summaries(@transactions_by_month_and_type, @selected_year)
  end

  private

  def prepare_category_data(categories, budgets, transactions)
    category_data = {}

    # Group budgets and transactions for quick lookup
    budgets_by_category = budgets.group_by(&:category_id)
    transactions_by_category_and_month = transactions.group_by { |t| [t.category_id, t.date.month] }

    categories.each do |category|
      next if category.parent_category.present? # Only process top-level categories

      category_data[category.id] = build_category_data(category, budgets_by_category, transactions_by_category_and_month)
    end

    category_data
  end

  def build_category_data(category, budgets_by_category, transactions_by_category_and_month)
    data = {
      category_type: category.category_type,
      category: category,
      budgeted_amount: calculate_budgeted_amount(category, budgets_by_category),
      monthly_transactions: calculate_monthly_transactions(category, transactions_by_category_and_month),
      total_transactions: 0,
      subcategories: []
    }

    # Sum up subcategories data
    if category.subcategories.any?
      category.subcategories.each do |subcategory|
        sub_data = {
          category: subcategory,
          budgeted_amount: calculate_budgeted_amount(subcategory, budgets_by_category),
          monthly_transactions: calculate_monthly_transactions(subcategory, transactions_by_category_and_month),
          total_transactions: 0
        }
        # Total transactions for subcategory
        sub_data[:total_transactions] = sub_data[:monthly_transactions].values.sum

        # Add subcategory data to main category
        data[:subcategories] << sub_data

        # Add subcategory amounts to parent category totals
        data[:budgeted_amount] += sub_data[:budgeted_amount]
        (1..12).each do |month|
          data[:monthly_transactions][month] += sub_data[:monthly_transactions][month]
        end
      end
    end

    # Total transactions for main category
    data[:total_transactions] = data[:monthly_transactions].values.sum

    data
  end

  def calculate_budgeted_amount(category, budgets_by_category)
    # Find yearly budget (month is nil)
    yearly_budget = budgets_by_category[category.id]&.find { |b| b.month.nil? }
    yearly_budget ? yearly_budget.budgeted_amount.to_i : 0
  end

  def calculate_monthly_transactions(category, transactions_by_category_and_month)
    monthly_transactions = Hash.new(0)
    (1..12).each do |month|
      transactions = transactions_by_category_and_month[[category.id, month]] || []
      monthly_transactions[month] = transactions.sum(&:amount)
    end
    monthly_transactions
  end

  def calculate_totals
    @budgeted_income_total = 0
    @budgeted_expense_total = 0
    @budgeted_savings_total = 0
    @budgeted_net_total = 0

    @monthly_income_totals = Hash.new(0)
    @monthly_expense_totals = Hash.new(0)
    @monthly_savings_totals = Hash.new(0)

    # Income Totals
    income_categories = @categories.select { |c| c.category_type == 'income' && c.parent_category.nil? }
    income_categories.each do |category|
      data = @category_data[category.id]
      @budgeted_income_total += data[:budgeted_amount]
      (1..12).each do |month|
        @monthly_income_totals[month] += data[:monthly_transactions][month]
      end
    end

    # Expense Totals
    expense_categories = @categories.select { |c| c.category_type == 'expense' && c.parent_category.nil? }
    expense_categories.each do |category|
      data = @category_data[category.id]
      @budgeted_expense_total += data[:budgeted_amount]
      (1..12).each do |month|
        @monthly_expense_totals[month] += data[:monthly_transactions][month]
      end
    end

    # Savings Totals
    savings_categories = @categories.select { |c| c.category_type == 'savings' && c.parent_category.nil? }
    savings_categories.each do |category|
      data = @category_data[category.id]
      @budgeted_savings_total += data[:budgeted_amount]
      (1..12).each do |month|
        @monthly_savings_totals[month] += data[:monthly_transactions][month]
      end
    end

    # Net Total
    @budgeted_net_total = @budgeted_income_total - @budgeted_expense_total
  end

  # Summarize each category within the month, including budgeted and actual amounts
  def prepare_monthly_category_summaries(transactions_by_month_and_type, year)
    summaries = {}
  
    (1..12).each do |month|
      month_name = Date::MONTHNAMES[month]
      summaries[month_name] = { 'income' => {}, 'expense' => {}, 'savings' => {} }
  
      ['income', 'expense', 'savings'].each do |type|
        categories = @categories.select { |c| c.category_type == type && c.parent_category.nil? }
  
        categories.each do |category|
          category_summary = {
            actual: 0,
            budgeted: 0,
            subcategories: {}
          }
  
          # Calculate actual amounts
          transactions = transactions_by_month_and_type[[month_name, type]]&.select { |t| t.category == category } || []
          category_summary[:actual] += transactions.sum(&:amount)
  
          # Calculate budgeted amounts
          monthly_budget = get_budgeted_amount(category, year, month_name)
          category_summary[:budgeted] += monthly_budget
  
          # Handle subcategories
          category.subcategories.each do |subcategory|
            subcategory_summary = {
              actual: 0,
              budgeted: 0
            }
  
            # Calculate actual amounts for subcategories
            sub_transactions = transactions_by_month_and_type[[month_name, type]]&.select { |t| t.category == subcategory } || []
            subcategory_summary[:actual] += sub_transactions.sum(&:amount)
  
            # Calculate budgeted amounts for subcategories
            sub_monthly_budget = get_budgeted_amount(subcategory, year, month_name)
            subcategory_summary[:budgeted] += sub_monthly_budget
  
            # Add subcategory summary to category summary
            category_summary[:actual] += subcategory_summary[:actual]
            category_summary[:budgeted] += subcategory_summary[:budgeted]
            category_summary[:subcategories][subcategory] = subcategory_summary
          end
  
          summaries[month_name][type][category] = category_summary
        end
      end
    end
  
    summaries
  end

  # Helper to fetch budgeted amount based on year and month
  def get_budgeted_amount(category, year, month)
    budget = Budget.find_by(category:, year:, month: Date::MONTHNAMES.index(month))
    if budget.nil?
      budget = Budget.yearly.find_by(category:, year:)
    end
    budget ? budget.budgeted_amount : 0
  end

  # Calculate subcategory totals for the category
  def get_subcategory_totals(category_transactions, year, month)
    category_transactions
      .group_by { |t| t.category }
      .transform_values { |transactions| { actual: transactions.sum(&:amount), budgeted: get_budgeted_amount(transactions.first.category, year, month) } }
      .reject { |category, _| category.parent_category.nil? }
  end
end