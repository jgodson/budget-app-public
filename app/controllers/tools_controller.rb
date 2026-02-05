class ToolsController < ApplicationController
  helper_method :max_investment_years

  def amortization
    loans = Loan.active.order(:loan_name)
    @loan_options = loans.map do |loan|
      last_payment = loan.loan_payments.order(payment_date: :desc).first
      {
        id: loan.id,
        name: loan.loan_name,
        balance_dollars: loan.balance_dollars,
        last_payment_dollars: last_payment ? (last_payment.paid_amount / 100.0) : 0,
        apr: loan.apr&.to_f
      }
    end
  end

  def investment
    @active_goals = Goal.active.includes(:category).order(:goal_name)
    @selected_goal = @active_goals.find { |goal| goal.id == params[:goal_id].to_i } if params[:goal_id].present?

    @goal_amount_from_params = params[:goal_amount_dollars].present?
    @initial_investment_from_params = params[:initial_investment_dollars].present?
    @contribution_amount_from_params = params[:contribution_amount_dollars].present?

    @goal_amount_dollars = parse_decimal(params[:goal_amount_dollars])
    @initial_investment_dollars = parse_decimal(params[:initial_investment_dollars])
    @contribution_amount_dollars = parse_decimal(params[:contribution_amount_dollars])
    @annual_return_rate = parse_decimal(params[:annual_return_rate])
    @contribution_frequency = params[:contribution_frequency].presence || "monthly"

    @goal_amount_dollars ||= @selected_goal&.amount_dollars || 10_000
    @initial_investment_dollars ||= @selected_goal&.total_contributed_dollars || 0
    @contribution_amount_dollars ||= 250
    @annual_return_rate ||= 0
    @goal_monthly_contributions = build_goal_monthly_contributions(@active_goals)
  end

  private

  def parse_decimal(value)
    return nil if value.blank?
    value.to_s.delete(",").to_f
  end

  def build_goal_monthly_contributions(goals)
    end_date = Date.current
    start_date = end_date - 12.months

    goals.each_with_object({}) do |goal, hash|
      total_cents = goal.category.transactions.where(date: start_date..end_date).sum(:amount)
      hash[goal.id] = (total_cents / 12.0 / 100.0).round(2)
    end
  end

  def max_investment_years
    100
  end
end
