require "application_system_test_case"
require "fileutils"

class TransactionsHeaderIndicatorTest < ApplicationSystemTestCase
  test "transactions header shows total columns" do
    visit transactions_path
    assert_selector("h5", text: "Transactions", wait: 5)
    assert_selector("[data-amount-totals]", wait: 5)
    assert_text("Income")
    assert_text("Expenses")
    assert_text("Savings")

    screenshot_path = ENV.fetch("SCREENSHOT_PATH", "issue3/after.png")
    FileUtils.mkdir_p(File.dirname(screenshot_path))
    save_screenshot(screenshot_path)
  end
end
