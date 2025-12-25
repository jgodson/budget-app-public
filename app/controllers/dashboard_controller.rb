class DashboardController < ApplicationController
  def index
    @selected_year = params[:year]&.to_i || Date.current.year
    @available_years = Transaction.distinct.pluck(:date).map { |date| date.year }
    @available_years += Budget.select(:year).distinct.pluck(:year)
    @available_years << Date.current.year
    @available_years = @available_years.uniq.sort.reverse

    # Fetch all categories including their subcategories
    @categories = Category.includes(:subcategories).order(:name)

    # Fetch budgets and transactions for the selected year
    year_range = Date.new(@selected_year, 1, 1)..Date.new(@selected_year, 12, 31)
    @budgets = Budget.where(year: @selected_year).includes(:category)
    @transactions = Transaction.where(date: year_range).includes(:category)

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

    # Prepare chart data
    prepare_chart_data
  end

  def monthly_overview
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month
    @selected_date = Date.new(year, month, 1)
    
    @prev_month = @selected_date - 1.month
    @next_month = @selected_date + 1.month

    @categories = Category.includes(:subcategories).order(:name)
    
    # Current Month Data
    range = @selected_date.beginning_of_month..@selected_date.end_of_month
    @transactions = Transaction.where(date: range).includes(:category)
    @budgets = Budget.where(year: year, month: month).or(Budget.where(year: year, month: nil)).includes(:category)
    
    # Previous Year Comparison Data
    prev_range = (@selected_date - 1.year).beginning_of_month..(@selected_date - 1.year).end_of_month
    @prev_transactions = Transaction.where(date: prev_range).includes(:category)

    prepare_monthly_details
    prepare_monthly_charts
  end

  private

  def prepare_monthly_details
    @monthly_details = {}
    
    # Helper to sum transactions for a category
    sum_transactions = ->(transactions, category) {
      transactions.select { |t| t.category_id == category.id }.sum(&:amount)
    }

    # Helper to find budget
    find_budget = ->(category) {
      b = @budgets.find { |b| b.category_id == category.id && b.month == @selected_date.month }
      b ||= @budgets.find { |b| b.category_id == category.id && b.month.nil? }
      b ? b.budgeted_amount : 0
    }

    @categories.each do |category|
      next if category.parent_category_id.present?

      # Process Subcategories First
      sub_details = category.subcategories.map do |sub|
        actual = sum_transactions.call(@transactions, sub)
        prev_actual = sum_transactions.call(@prev_transactions, sub)
        budget = find_budget.call(sub)
        
        {
          category: sub,
          actual: actual,
          budget: budget,
          prev_actual: prev_actual,
          percent: budget > 0 ? (actual.to_f / budget * 100) : 0
        }
      end

      # Process Main Category
      actual = sum_transactions.call(@transactions, category)
      prev_actual = sum_transactions.call(@prev_transactions, category)
      budget = find_budget.call(category)

      # Add Subcategory Totals
      actual += sub_details.sum { |d| d[:actual] }
      prev_actual += sub_details.sum { |d| d[:prev_actual] }
      budget += sub_details.sum { |d| d[:budget] }

      @monthly_details[category] = {
        category: category,
        actual: actual,
        budget: budget,
        prev_actual: prev_actual,
        percent: budget > 0 ? (actual.to_f / budget * 100) : 0,
        subcategories: sub_details
      }
    end
  end

  def prepare_monthly_charts
    build_dataset = ->(type, color) {
      categories = @monthly_details.values.select { |d| d[:category].category_type == type }
                                  .sort_by { |d| -d[:actual] }
      
      {
        labels: categories.map { |d| d[:category].name },
        datasets: [
          {
            label: "Current (#{@selected_date.year})",
            data: categories.map { |d| d[:actual] / 100.0 },
            backgroundColor: color,
            borderColor: color.gsub('0.4', '1.0'),
            borderWidth: 1
          },
          {
            label: "Prior (#{@selected_date.year - 1})",
            data: categories.map { |d| d[:prev_actual] / 100.0 },
            backgroundColor: 'rgba(201, 203, 207, 0.4)',
            borderColor: '#c9cbcf',
            borderWidth: 1
          }
        ]
      }
    }

    @income_comparison_data = build_dataset.call('income', 'rgba(25, 135, 84, 0.4)')
    @expense_comparison_data = build_dataset.call('expense', 'rgba(220, 53, 69, 0.4)')
    @savings_comparison_data = build_dataset.call('savings', 'rgba(13, 110, 253, 0.4)')
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

  private

  def prepare_chart_data
    # 1. Income vs Expense vs Savings (Yearly Total - Pie Chart)
    total_income = @monthly_income_totals.values.sum / 100.0
    total_expenses = @monthly_expense_totals.values.sum / 100.0
    total_savings = @monthly_savings_totals.values.sum / 100.0
    remaining = total_income - (total_expenses + total_savings)
    @yearly_net_total = remaining

    if remaining >= 0
      @overview_chart_data = {
        labels: ['Expenses', 'Savings', 'Remaining'],
        datasets: [{
          data: [total_expenses, total_savings, remaining],
          backgroundColor: ['rgba(220, 53, 69, 0.4)', 'rgba(13, 110, 253, 0.4)', 'rgba(25, 135, 84, 0.4)'],
          borderColor: ['#dc3545', '#0d6efd', '#198754'],
          borderWidth: 1,
          hoverOffset: 4
        }]
      }
    else
      @overview_chart_data = {
        labels: ['Expenses', 'Savings'],
        datasets: [{
          data: [total_expenses, total_savings],
          backgroundColor: ['rgba(220, 53, 69, 0.4)', 'rgba(13, 110, 253, 0.4)'],
          borderColor: ['#dc3545', '#0d6efd'],
          borderWidth: 1,
          hoverOffset: 4
        }]
      }
    end

    # 2. Monthly Breakdown (Income, Expense, Savings - Line Chart)
    current_year_totals = {
      income: @monthly_income_totals,
      expense: @monthly_expense_totals,
      savings: @monthly_savings_totals
    }
    
    # Fetch Previous Year Data
    prev_year = @selected_year - 1
    prev_year_transactions = Transaction.where(date: Date.new(prev_year, 1, 1)..Date.new(prev_year, 12, 31)).includes(:category)
    prev_year_totals = { income: Hash.new(0), expense: Hash.new(0), savings: Hash.new(0) }
    
    prev_year_transactions.each do |t|
      month = t.date.month
      type = t.category.category_type
      prev_year_totals[type.to_sym][month] += t.amount
    end

    @monthly_breakdown_data = {
      labels: Date::MONTHNAMES.compact,
      datasets: [
        # Current Year - Income
        {
          label: "Income (#{@selected_year})",
          data: (1..12).map { |m| (current_year_totals[:income][m] || 0) / 100.0 },
          borderColor: 'rgba(25, 135, 84, 0.6)',
          backgroundColor: 'rgba(25, 135, 84, 0.4)',
          tension: 0.4,
          fill: false
        },
        # Current Year - Expenses
        {
          label: "Expenses (#{@selected_year})",
          data: (1..12).map { |m| (current_year_totals[:expense][m] || 0) / 100.0 },
          borderColor: 'rgba(220, 53, 69, 0.6)',
          backgroundColor: 'rgba(220, 53, 69, 0.4)',
          tension: 0.4,
          fill: false
        },
        # Current Year - Savings
        {
          label: "Savings (#{@selected_year})",
          data: (1..12).map { |m| (current_year_totals[:savings][m] || 0) / 100.0 },
          borderColor: 'rgba(13, 110, 253, 0.6)',
          backgroundColor: 'rgba(13, 110, 253, 0.4)',
          tension: 0.4,
          fill: false
        },
        # Previous Year - Income (Dotted)
        {
          label: "Income (#{prev_year})",
          data: (1..12).map { |m| (prev_year_totals[:income][m] || 0) / 100.0 },
          borderColor: 'rgba(25, 135, 84, 0.4)',
          backgroundColor: 'rgba(25, 135, 84, 0.1)',
          borderDash: [5, 5],
          tension: 0.4,
          fill: false,
          hidden: false
        },
        # Previous Year - Expenses (Dotted)
        {
          label: "Expenses (#{prev_year})",
          data: (1..12).map { |m| (prev_year_totals[:expense][m] || 0) / 100.0 },
          borderColor: 'rgba(220, 53, 69, 0.4)',
          backgroundColor: 'rgba(220, 53, 69, 0.1)',
          borderDash: [5, 5],
          tension: 0.4,
          fill: false,
          hidden: false
        },
        # Previous Year - Savings (Dotted)
        {
          label: "Savings (#{prev_year})",
          data: (1..12).map { |m| (prev_year_totals[:savings][m] || 0) / 100.0 },
          borderColor: 'rgba(13, 110, 253, 0.4)',
          backgroundColor: 'rgba(13, 110, 253, 0.1)',
          borderDash: [5, 5],
          tension: 0.4,
          fill: false,
          hidden: false
        }
      ]
    }

    # 3. Category Breakdowns (Income, Expense, Savings)
    bg_colors = ['rgba(255, 99, 132, 0.4)', 'rgba(54, 162, 235, 0.4)', 'rgba(255, 206, 86, 0.4)', 'rgba(75, 192, 192, 0.4)', 'rgba(153, 102, 255, 0.4)', 'rgba(255, 159, 64, 0.4)']
    border_colors = ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0', '#9966FF', '#FF9F40']

    process_chart_data = ->(type) {
      categories = @category_data.values.select { |data| data[:category_type] == type }
                                        .sort_by { |data| -data[:total_transactions] }
      {
        labels: categories.map { |data| data[:category].name },
        datasets: [{
          label: type.capitalize,
          data: categories.map { |data| data[:total_transactions] / 100.0 },
          backgroundColor: categories.map.with_index { |_, i| bg_colors[i % bg_colors.length] },
          borderColor: categories.map.with_index { |_, i| border_colors[i % border_colors.length] },
          borderWidth: 1
        }]
      }
    }

    @income_by_category_data = process_chart_data.call('income')
    @expenses_by_category_data = process_chart_data.call('expense')
    @savings_by_category_data = process_chart_data.call('savings')
  end
end