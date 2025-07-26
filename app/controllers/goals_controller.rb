class GoalsController < ApplicationController
  before_action :set_goal, only: [:show, :edit, :update, :destroy, :archive, :unarchive]

  def index
    @active_goals = Goal.active.includes(:category)
    @archived_goals = Goal.archived.includes(:category)
    @goals = @active_goals + @archived_goals
  end

  def show
  end

  def new
    @goal = Goal.new(any_params.except(:amount_dollars))
    if params[:amount_dollars].present?
      @goal.amount = (params[:amount_dollars].to_f * 100).round
    end

    @categories = Category.savings
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
    @categories = Category.savings
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