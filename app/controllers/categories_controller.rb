class CategoriesController < ApplicationController
  def index
    @categories = Category.includes(:subcategories).where(parent_category_id: nil)
  end

  def show
    @category = Category.find(params[:id])
  end

  def new
    @category = Category.new
    @parent_categories = Category.where(parent_category_id: nil)
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Category created successfully."
    else
      flash[:model_errors] = @category.errors.full_messages
      redirect_to new_category_path
    end
  end

  def edit
    @category = Category.find(params[:id])
    @parent_categories = Category.where(parent_category_id: nil).where.not(id: @category.id)
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
  end

  private

  def category_params
    params.require(:category).permit(:name, :parent_category_id, :category_type)
  end
end