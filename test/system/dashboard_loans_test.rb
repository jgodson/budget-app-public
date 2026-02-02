require "application_system_test_case"
require "fileutils"

class DashboardLoansTest < ApplicationSystemTestCase
  test "paid off loans without activity in selected year are hidden" do
    selected_year = Date.current.year
    active_category = Category.create!(name: "Active Loan Expense", category_type: :expense)
    inactive_category = Category.create!(name: "Inactive Loan Expense", category_type: :expense)

    active_year_loan = Loan.create!(loan_name: "Paid Off Active Year", balance: 0, category: active_category)
    inactive_year_loan = Loan.create!(loan_name: "Paid Off Inactive Year", balance: 0, category: inactive_category)

    LoanPayment.create!(
      loan: active_year_loan,
      paid_amount: 10_000,
      interest_amount: 0,
      payment_date: Date.new(selected_year, 6, 15)
    )
    LoanPayment.create!(
      loan: inactive_year_loan,
      paid_amount: 10_000,
      interest_amount: 0,
      payment_date: Date.new(selected_year - 1, 6, 15)
    )

    visit root_path(year: selected_year)

    assert_text "Paid Off Active Year"
    loans_header = page.find("h5", text: "Loans")
    page.execute_script("arguments[0].scrollIntoView(true);", loans_header)
    FileUtils.mkdir_p("tmp/screenshots")
    page.save_screenshot("tmp/screenshots/dashboard-loans.png")
    assert_no_text "Paid Off Inactive Year"
  end
end
