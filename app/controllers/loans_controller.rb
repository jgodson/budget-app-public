class LoansController < ApplicationController
  def index
    @active_loans = Loan.active
    @paid_off_loans = Loan.paid_off
    @loans = @active_loans + @paid_off_loans
  end

  def show
    @loan = Loan.find(params[:id])

    respond_to do |format|
      format.html do
        @totals_by_year = @loan.payments_by_year.transform_values do |payments|
          {
            total_paid: payments.sum(&:paid_amount),
            total_interest: payments.sum(&:interest_amount),
            total_principal: payments.sum { |payment| payment.paid_amount - payment.interest_amount }
          }
        end
        render :show
      end
      format.json { render json: @loan.as_json.merge(last_payment: @loan.last_payment&.paid_amount || 0 ) }
    end
  end

  def new
    @loan = Loan.new
    @categories = Category.expenses
  end

  def create
    @loan = Loan.new(loan_params)
    @loan.balance = (params[:loan][:balance_dollars].to_f * 100).round
    if @loan.save
      redirect_to loans_path, notice: 'Loan was successfully created.'
    else
      flash[:model_errors] = @loan.errors.full_messages
      redirect_to new_loan_path
    end
  end

  def edit
    @loan = Loan.find(params[:id])
    @categories = Category.expenses
  end

  def update
    @loan = Loan.find(params[:id])
    @loan.balance = (params[:loan][:balance_dollars].to_f * 100).round
    if @loan.update(loan_params)
      redirect_to loans_path, notice: 'Loan was successfully updated.'
    else
      flash[:model_errors] = @loan.errors.full_messages
      redirect_to edit_loan_path
    end
  end

  def destroy
    @loan = Loan.find(params[:id])
    @loan.destroy
    redirect_to loans_path, notice: 'Loan was successfully deleted.'
  end

  private

  def loan_params
    params.require(:loan).permit(:loan_name, :category_id)
  end
end
