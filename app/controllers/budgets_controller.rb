class BudgetsController < ApplicationController
  include Import

  def index
    @categories = Category.all.order(:name)
    @selected_year = params[:year].nil? ? Date.today.year : params[:year].to_i
    @budgets = Budget.where(year: @selected_year)
    @next_year = @selected_year >= Date.today.year ? @selected_year + 1 : Date.today.year + 1
    @available_years = Budget.distinct.pluck(:year).sort.reverse
  end

  def show
    @budget = Budget.find(params[:id])
    year_range = Date.new(@budget.year, 1, 1)..Date.new(@budget.year, 12, 31)
    @transactions = @budget.category.transactions.where(date: year_range).order(date: :asc)
  end

  def edit
    @budget = Budget.find(params[:id])
    @categories = Category.all.order(:name)
    @related_months = Budget.where(
      year: @budget.year,
      category_id: @budget.category_id,
      budgeted_amount: @budget.budgeted_amount
    ).monthly.pluck(:month)
  end

  def new
    @selected_year = params[:year].nil? ? Date.today.year : params[:year].to_i
    category = params[:category_id].nil? ? nil : Category.find(params[:category_id].to_i)
    @budget = Budget.new(year: @selected_year, category:)
    @categories = Category.all.order(:name)
  end

  def create
    months = params[:budget][:months]

    if months.present?
      saved_count = 0
      errors = []

      months.each do |m|
        budget = Budget.find_or_initialize_by(
          year: params[:budget][:year],
          category_id: params[:budget][:category_id],
          month: m
        )
        budget.budgeted_amount = (params[:budget][:budgeted_amount_dollars].to_f * 100).round

        if budget.save
          saved_count += 1
        else
          errors << "Month #{m}: #{budget.errors.full_messages.join(', ')}"
        end
      end

      if errors.empty?
        redirect_to budgets_path(year: params[:budget][:year]), notice: "#{saved_count} budget(s) successfully created."
      else
        flash[:model_errors] = errors
        redirect_to new_budget_path(year: params[:budget][:year], category_id: params[:budget][:category_id])
      end
    else
      @budget = Budget.new(budget_params.except(:months))
      @budget.budgeted_amount = (params[:budget][:budgeted_amount_dollars].to_f * 100).round
      if @budget.save
        redirect_to budgets_path(year: @budget.year), notice: 'Budget was successfully created.'
      else
        flash[:model_errors] = @budget.errors.full_messages
        redirect_to new_budget_path(year: @budget.year)
      end
    end
  end

  def update
    @budget = Budget.find(params[:id])
    months = params[:budget][:months] || []
    
    # Prepare attributes
    new_attrs = budget_params.except(:months, :budgeted_amount_dollars)
    new_amount = (params[:budget][:budgeted_amount_dollars].to_f * 100).round
    
    primary_month = months.shift # Returns first or nil
    
    @budget.assign_attributes(new_attrs)
    @budget.month = primary_month
    @budget.budgeted_amount = new_amount
    
    if @budget.save
      if months.any?
        months.each do |m|
          other_budget = Budget.find_or_initialize_by(
            year: @budget.year,
            category_id: @budget.category_id,
            month: m
          )
          other_budget.budgeted_amount = new_amount
          other_budget.save
        end
      end
      redirect_to budgets_path(year: @budget.year), notice: 'Budget was successfully updated.'
    else
      flash[:model_errors] = @budget.errors.full_messages
      redirect_to edit_budget_path
    end
  end

  def destroy
    @budget = Budget.find(params[:id])
    if @budget.destroy
      redirect_to budgets_path(year: @budget.year), notice: 'Budget was successfully deleted.'
    else
      flash[:model_errors] = @budget.errors.full_messages
      redirect_to budgets_path(year: @budget.year)
    end
  end

  def copy_yearly_budgets
    current_year = params[:year].nil? ? Date.today.year : params[:year].to_i
    next_year = current_year + 1
    yearly_budgets = Budget.where(year: current_year, month: nil)

    yearly_budgets.each do |budget|
      Budget.create(
        year: next_year,
        budgeted_amount: budget.budgeted_amount,
        category_id: budget.category_id
      )
    end

    redirect_to budgets_path(year: next_year), notice: "Yearly budgets successfully copied to #{next_year}."
  end

  def import_form
  end

  def import_preview
    file = params[:file]

    if file.nil?
      flash.now[:alert] = "Please select a file to upload."
      render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
      return
    end

    begin
      service = ImportServiceLoader.service_for_file(file, Budget)
      
      if service.present?
        @preview_data = service.preview
      else
        flash.now[:alert] = "Invalid import type selected."
        render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
        return
      end

      if @preview_data.empty?
        Rails.logger.info("No importable data found in the file.")
        flash.now[:alert] = "No importable data found in the file."
        render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
        return
      end
    rescue Errors::InvalidFileError => err
      Rails.logger.error(err)
      flash.now[:alert] = err.message
      render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
      return
    rescue StandardError => err
      Rails.logger.error(err)
      flash.now[:alert] = "An error occurred while processing the file. Please try again."
      render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
      return
    end

    if @preview_data[:items].empty?
      flash.now[:alert] = "No budgets found for import."
      render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
      return
    end

    @categories = (Category.all.order(:name) + @preview_data[:new_categories]).sort_by(&:name)

    respond_to do |format|
      format.turbo_stream
      format.html { render :import_preview }
    end
  end

  def import
    if params[:selected_budgets].nil?
      redirect_to import_form_budgets_path, alert: "No budgets selected to import."
      return
    end

    selected_budgets = params[:selected_budgets].map { |t| JSON.parse(t) }
    import_budgets(selected_budgets)
    redirect_to budgets_path(year: selected_budgets[0]['year']), notice: "Budgets imported successfully."
  end

  private

  def import_budgets(selected_budgets)
    extracted_categories = selected_budgets.map { |b| b['category'] }
    selected_budgets.each_with_index do |budget_data, index|
      unique_id = budget_data['unique_id']
      category_name = params["budget_category_#{unique_id}"]
      
      # If a category was not originally found in the file, it will not have a category_type
      # (ie: if something was changed to an existing category). In that case we just find by name.
      extracted_category = extracted_categories.find { |c| c['name'] == category_name }

      category = if extracted_category
        Category.find_or_create_by(
          name: category_name,
          category_type: extracted_category['category_type']
        )
      else
        Category.find_or_create_by(name: category_name)
      end

      Budget.create!(
        category: category,
        year: budget_data['year'],
        budgeted_amount: budget_data['amount']
      )
    end
  end

  def budget_params
    params.require(:budget).permit(:category_id, :year, :month, months: [])
  end
end