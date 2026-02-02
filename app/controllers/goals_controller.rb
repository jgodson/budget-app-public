class GoalsController < ApplicationController
  before_action :set_goal, only: [:show, :edit, :update, :destroy, :archive, :unarchive]

  def index
    @active_goals = Goal.active.includes(:category)
                           .sort_by { |goal| [-goal.percent_complete, goal.goal_name.to_s.downcase] }
    @archived_goals = Goal.archived.includes(:category)
                              .sort_by { |goal| [-goal.percent_complete, goal.goal_name.to_s.downcase] }
    @goals = @active_goals + @archived_goals
  end

  def show
    # Chart Data Preparation
    current_year = @selected_year || Date.current.year
    prior_year = current_year - 1
    
    # Get transactions for the goal's category
    transactions = @goal.category.transactions
    
    # Initialize data arrays for 12 months
    current_year_data = Array.new(12, 0)
    prior_year_data = Array.new(12, 0)
    
    # Filter and sum transactions
    transactions.each do |t|
      month_index = t.date.month - 1
      amount = t.amount / 100.0
      
      if t.date.year == current_year
        current_year_data[month_index] += amount
      elsif t.date.year == prior_year
        prior_year_data[month_index] += amount
      end
    end
    
    labels = Date::MONTHNAMES.compact # ["January", "February", ...]
    
    max_val = [current_year_data.max, prior_year_data.max].max
    @goals_chart_max = (max_val * 1.2).ceil

    @contributions_chart_data = {
      labels: labels,
      datasets: [
        {
          label: "#{current_year} Contributions",
          data: current_year_data,
          borderColor: '#198754', # Success Green
          backgroundColor: 'rgba(25, 135, 84, 0.1)',
          fill: true,
          tension: 0.4
        },
        {
          label: "#{prior_year} Contributions",
          data: prior_year_data,
          borderColor: '#6c757d', # Secondary Gray
          backgroundColor: 'rgba(108, 117, 125, 0.1)',
          fill: true,
          tension: 0.4,
          borderDash: [5, 5]
        }
      ]
    }
  end

  def new
    @goal = Goal.new(any_params.except(:amount_dollars))
    if params[:amount_dollars].present?
      @goal.amount = (params[:amount_dollars].to_f * 100).round
    end

    @categories = Category.savings.order(:name)
  end

  def create
    @goal = Goal.new(goal_params.except(:amount_dollars))
    @goal.amount = (params[:goal][:amount_dollars].to_f * 100).round
    if @goal.save
      redirect_to goals_path, notice: 'Goal was successfully created.'
    else
      flash[:model_errors] = @goal.errors.full_messages
      redirect_to new_goal_path(goal_params)
    end
  end

  def edit
    @categories = Category.savings.order(:name)
  end

  def update
    if @goal.update(goal_params)
      redirect_to @goal, notice: 'Goal was successfully updated.'
    else
      flash[:model_errors] = @goal.errors.full_messages
      redirect_to edit_goal_path
    end
  end

  def destroy
    if @goal.destroy
      redirect_to goals_path, notice: 'Goal was successfully deleted.'
    else
      flash[:model_errors] = @goal.errors.full_messages
      redirect_to goals_path(@goal)
    end
  end

  def archive
    @goal.archive
    redirect_to goal_path(@goal), notice: 'Goal was successfully archived.'
  end

  def unarchive
    @goal.unarchive
    redirect_to goal_path(@goal), notice: 'Goal was successfully unarchived.'
  end

  private

  def set_goal
    @goal = Goal.find(params[:id])
  end

  def goal_params
    params.require(:goal).permit(:goal_name, :category_id, :amount_dollars)
  end

  def any_params
    params.permit(:goal_name, :category_id, :amount_dollars)
  end
end
