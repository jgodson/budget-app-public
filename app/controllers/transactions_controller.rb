class TransactionsController < ApplicationController
  include Import

  GROUP_BY_OPTIONS = ['year & category', 'month & category', 'year', 'month'].freeze

  def index
    @selected_year = params[:year]&.to_i || Date.current.year
    @selected_month = params[:month].presence&.to_i
    @selected_category = params[:category].presence&.to_i
    @selected_group_by = params[:group_by] || GROUP_BY_OPTIONS[0]
    @group_by_options = GROUP_BY_OPTIONS

    @available_years = Transaction.distinct.pluck(:date).map { |date| date.year }.uniq.sort.reverse

    @transactions = Transaction.where("strftime('%Y', date) = ?", @selected_year.to_s)
                               .includes(:category)
                               .order(:date)

    if @selected_month.present?
      @transactions = @transactions.where("strftime('%m', date) = ?", format('%02d', @selected_month))
    end

    if @selected_category.present?
      @transactions = @transactions.where(category_id: @selected_category)
    end

    # Group transactions by selected group_by option
    if @selected_group_by.include?('month')
      @grouped_transactions = @transactions.group_by { |t| t.date.beginning_of_month }
    else
      @grouped_transactions = @transactions.group_by { |t| t.date.year }
    end

    if @selected_group_by.include?('category')
      @grouped_transactions.each do |date, transactions|
        @grouped_transactions[date] = transactions.group_by(&:category)
      end
    end

    @categories = Category.all
  end

  def show
    @transaction = Transaction.find(params[:id])
  end

  def new
    @transaction = Transaction.new(any_params)
    @transaction.date = @transaction.date.presence || Date.today
    @categories = Category.all
  end

  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.amount = (params[:transaction][:amount_dollars].to_f * 100).round
    @transaction.description = @transaction.description.presence || @transaction.category.name
    if @transaction.save
      redirect_to transactions_path, notice: 'Transaction was successfully created.'
    else
      @categories = Category.all
      flash[:model_errors] = @transaction.errors.full_messages
      redirect_to new_transaction_path
    end
  end

  def edit
    @transaction = Transaction.find(params[:id])
    @categories = Category.all
  end

  def update
    @transaction = Transaction.find(params[:id])
    @transaction.amount = (params[:transaction][:amount_dollars].to_f * 100).round
    if @transaction.update(transaction_params)
      redirect_to transactions_path, notice: 'Transaction was successfully updated.'
    else
      @categories = Category.all
      render :edit
    end
  end

  def destroy
    @transaction = Transaction.find(params[:id])
    if @transaction.destroy
      redirect_to transactions_path, notice: 'Transaction was successfully deleted.'
    else
      flash[:model_errors] = @transaction.errors.full_messages
      redirect_to transactions_path
    end
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
      service = ImportServiceLoader.service_for_file(file, Transaction)
      
      if service.present?
        @preview_data = service.preview
      else
        flash.now[:alert] = "The file does not appear to be valid for import."
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
      flash.now[:alert] = err.message
      render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
      return
    rescue StandardError => err
      raise err
      flash.now[:alert] = "An error occurred while processing the file. Please try again."
      render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
      return
    end

    if @preview_data[:items].empty?
      flash.now[:alert] = "No transactions found for import."
      render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash_messages")
      return
    end

    @categories = Category.all + @preview_data[:new_categories]

    respond_to do |format|
      format.turbo_stream
    end
  end

  def import
    if params[:selected_transactions].nil?
      redirect_to import_form_transactions_path, alert: "No transactions selected to import."
      return
    end

    selected_transactions = params[:selected_transactions].map { |t| JSON.parse(t) }
    import_selected_transactions(selected_transactions)
    redirect_to transactions_path, notice: "Transactions imported successfully."
  end

  private

  def import_selected_transactions(selected_transactions)
    extracted_categories = selected_transactions.map { |b| b['category'] }
    selected_transactions.each do |transaction_data|
      unique_id = transaction_data['unique_id']
      category_name = params["transaction_category_#{unique_id}"]
      
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

      Transaction.create!(
        category: category,
        date: transaction_data['date'],
        amount: transaction_data['amount'],
        description: transaction_data['description'],
      )
    end
  end

  def transaction_params
    params.require(:transaction).permit(:category_id, :date, :description)
  end

  def any_params
    params.permit(:category_id, :date, :description)
  end
end