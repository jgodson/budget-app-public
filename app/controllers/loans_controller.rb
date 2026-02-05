class LoansController < ApplicationController
  def index
    @active_loans = Loan.active
                        .sort_by { |loan| [-loan.percent_complete, loan.loan_name.to_s.downcase] }
    @paid_off_loans = Loan.paid_off
                          .sort_by { |loan| [-loan.percent_complete, loan.loan_name.to_s.downcase] }
    @loans = @active_loans + @paid_off_loans
  end

  def show
    @loan = Loan.find(params[:id])

    # Chart Data Preparation
    current_year = @selected_year || Date.current.year
    prior_year = current_year - 1
    
    # Get payments for current and prior year
    start_date = Date.new(prior_year, 1, 1)
    end_date = Date.new(current_year, 12, 31)
    payments = @loan.loan_payments.where(payment_date: start_date..end_date)
    
    # Initialize data arrays for 12 months
    current_year_total = Array.new(12, 0)
    prior_year_total = Array.new(12, 0)
    
    current_year_principal = Array.new(12, 0)
    prior_year_principal = Array.new(12, 0)
    
    current_year_interest = Array.new(12, 0)
    prior_year_interest = Array.new(12, 0)
    
    payments.each do |p|
      month_index = p.payment_date.month - 1
      amount = p.paid_amount / 100.0
      interest = p.interest_amount / 100.0
      principal = amount - interest
      
      if p.payment_date.year == current_year
        current_year_total[month_index] += amount
        current_year_principal[month_index] += principal
        current_year_interest[month_index] += interest
      elsif p.payment_date.year == prior_year
        prior_year_total[month_index] += amount
        prior_year_principal[month_index] += principal
        prior_year_interest[month_index] += interest
      end
    end
    
    labels = Date::MONTHNAMES.compact

    max_total = [current_year_total.max, prior_year_total.max].max
    @total_chart_max = (max_total * 1.2).ceil
    
    max_principal = [current_year_principal.max, prior_year_principal.max].max
    @principal_chart_max = (max_principal * 1.2).ceil

    max_interest = [current_year_interest.max, prior_year_interest.max].max
    @interest_chart_max = (max_interest * 1.2).ceil

    @total_payments_chart_data = {
        labels: labels,
        datasets: [
          { label: "#{current_year} Total", data: current_year_total, borderColor: '#0d6efd', backgroundColor: 'rgba(13, 110, 253, 0.1)', fill: true, tension: 0.4 },
          { label: "#{prior_year} Total", data: prior_year_total, borderColor: '#6c757d', backgroundColor: 'rgba(108, 117, 125, 0.1)', fill: true, tension: 0.4, borderDash: [5, 5] }
        ]
    }
    @principal_payments_chart_data = {
        labels: labels,
        datasets: [
          { label: "#{current_year} Principal", data: current_year_principal, borderColor: '#0dcaf0', backgroundColor: 'rgba(13, 202, 240, 0.1)', fill: true, tension: 0.4 },
          { label: "#{prior_year} Principal", data: prior_year_principal, borderColor: '#6c757d', backgroundColor: 'rgba(108, 117, 125, 0.1)', fill: true, tension: 0.4, borderDash: [5, 5] }
        ]
    }
    @interest_payments_chart_data = {
        labels: labels,
        datasets: [
          { label: "#{current_year} Interest", data: current_year_interest, borderColor: '#ffc107', backgroundColor: 'rgba(255, 193, 7, 0.1)', fill: true, tension: 0.4 },
          { label: "#{prior_year} Interest", data: prior_year_interest, borderColor: '#6c757d', backgroundColor: 'rgba(108, 117, 125, 0.1)', fill: true, tension: 0.4, borderDash: [5, 5] }
        ]
    }

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
    @categories = Category.expenses.order(:name)
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
    @categories = Category.expenses.order(:name)
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
    params.require(:loan).permit(:loan_name, :category_id, :apr)
  end
end
