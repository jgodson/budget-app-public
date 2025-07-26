class LoanPaymentsController < ApplicationController
    before_action :set_loan_payment, only: %i[destroy]
    before_action :set_loans, only: %i[new create]
  
    def new
      @loan_payment = LoanPayment.new(any_params)
      @loan_payment.payment_date = @loan_payment.payment_date.presence || Date.today
    end
    
    def destroy
      loan = @loan_payment.loan
      principal_paid = @loan_payment.paid_amount - @loan_payment.interest_amount
      loan.update(balance: loan.balance + principal_paid)
      @loan_payment.destroy
      redirect_to loan_path(loan), notice: 'Loan payment was successfully deleted.'
    end
  
    def create
      @loan_payment = LoanPayment.new(loan_payment_params.except(:paid_amount_dollars, :new_balance_dollars))
      loan = @loan_payment.loan
      @loan_payment.paid_amount = (params[:loan_payment][:paid_amount_dollars].to_f * 100).round
      new_balance = (params[:loan_payment][:new_balance_dollars].to_f * 100).round

      if @loan_payment.paid_amount && new_balance
        # Calculate interest paid
        @loan_payment.interest_amount = @loan_payment.paid_amount - (loan.balance - new_balance)
      end
  
      if @loan_payment.save
        loan.update(balance: new_balance)
        redirect_to loans_path, notice: 'Loan payment was successfully created.'
      else
        flash[:model_errors] = @loan_payment.errors.full_messages
        redirect_to new_loan_payment_path
      end
    end
  
    private
  
    def set_loan_payment
      @loan_payment = LoanPayment.find(params[:id])
    end
  
    def set_loans
      @loans = Loan.all
    end
  
    def loan_payment_params
      params.require(:loan_payment).permit(:loan_id, :payment_date)
    end

    def any_params
      params.permit(:loan_id, :payment_date)
    end
  end
  