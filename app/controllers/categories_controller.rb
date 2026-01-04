class CategoriesController < ApplicationController
  def index
    @categories = Category.includes(:subcategories).where(parent_category_id: nil)
  end

  def show
    @category = Category.find(params[:id])
    
    # Default to current year for stats/charts
    @year = Date.today.year
    
    # Stats (YTD)
    start_date = Date.new(@year, 1, 1)
    end_date = Date.today
    @total_spent_ytd = @category.transactions.where(date: start_date..end_date).sum(:amount)
    @avg_monthly_spend = Date.today.month > 0 ? (@total_spent_ytd / Date.today.month.to_f) : 0
    
    # Chart Data (Monthly for Current Year vs Prior Year)
    @current_year_data = (1..12).map do |month|
      s = Date.new(@year, month, 1)
      e = s.end_of_month
      @category.transactions.where(date: s..e).sum(:amount) / 100.0
    end
    
    @prior_year_data = (1..12).map do |month|
      s = Date.new(@year - 1, month, 1)
      e = s.end_of_month
      @category.transactions.where(date: s..e).sum(:amount) / 100.0
    end
    
    max_val = [@current_year_data.max, @prior_year_data.max].max
    @chart_max = (max_val * 1.2).round
  end

  def new
    @category = Category.new
    @parent_categories = Category.where(parent_category_id: nil).order(:name)
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Category created successfully.", status: :see_other
    else
      flash[:model_errors] = @category.errors.full_messages
      redirect_to new_category_path
    end
  end

  def edit
    @category = Category.find(params[:id])
    @parent_categories = Category.where(parent_category_id: nil).where.not(id: @category.id).order(:name)
  end

  def update
    @category = Category.find(params[:id])
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated successfully."
    else
      flash[:model_errors] = @category.errors.full_messages
      redirect_to edit_category_path
    end
  end

  def destroy
    @category = Category.find(params[:id])
    if @category.subcategories.present?
      flash[:model_errors] = @budget.errors.full_messages
      redirect_to budgets_path(year: @budget.year)
      return
    end

    if params[:new_category_id].present?
      new_category = Category.find(params[:new_category_id])
      @category.transactions.update_all(category_id: new_category.id)
    end
    if @category.destroy
      if new_category.present?
        flash[:notice] = "Category deleted successfully, and category transactions were moved to the new category."
      else
        flash[:notice] = "Category deleted successfully."
      end
      redirect_to categories_path
    else
      flash[:alert] = "Category could not be deleted, however category transactions were moved to the new category."
      flash[:model_errors] = @category.errors.full_messages
      redirect_to categories_path
    end
  end

  def destroy_confirm
    @category = Category.find(params[:id])
    @categories = Category.where.not(id: @category.id).order(:name)
  end

  def average_spending
    category = Category.find(params[:id])
    
    # Calculate average spending over the last 12 months
    end_date = Date.today
    start_date = end_date - 12.months
    
    total_spent = category.transactions.where(date: start_date..end_date).sum(:amount)
    average_cents = total_spent / 12.0
    average_dollars = (average_cents / 100.0).round(2)
    
    render json: { average: average_dollars }
  end

  private

  def category_params
    params.require(:category).permit(:name, :parent_category_id, :category_type)
  end
end