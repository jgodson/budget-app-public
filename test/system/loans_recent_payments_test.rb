require "application_system_test_case"

class LoansRecentPaymentsTest < ApplicationSystemTestCase
  test "paid off loans do not show recent payments action" do
    visit loans_path

    take_screenshot

    within(:xpath, "//tr[.//span[contains(normalize-space(), 'Paid Off Loan')]]") do
      assert_selector "i.bi-clock-history", visible: :all
    end

    within(:xpath, "//tr[.//span[contains(normalize-space(), 'Paid Off Old Loan')]]") do
      assert_no_selector "i.bi-clock-history", visible: :all
    end
  end
end
