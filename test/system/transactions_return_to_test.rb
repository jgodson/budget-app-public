require "application_system_test_case"
require "fileutils"

class TransactionsReturnToTest < ApplicationSystemTestCase
  test "editing a transaction returns to the filtered list" do
    transaction = transactions(:salary)
    return_to_params = {
      year: transaction.date.year,
      month: transaction.date.month,
      category: transaction.category_id,
      group_by: "month & category",
    }

    use_return_to = ENV["USE_RETURN_TO"] != "false"
    if use_return_to
      return_to = transactions_path(return_to_params)
      visit edit_transaction_path(transaction, return_to: return_to)
    else
      visit edit_transaction_path(transaction)
    end

    category_select = find("select#transaction_category_id_select", visible: false)
    category_select.find("option[value='#{transaction.category_id}']", visible: false).select_option
    fill_in "Date", with: transaction.date.strftime("%Y-%m-%d")
    fill_in "Description", with: "Updated Rent"
    fill_in "Amount", with: "2000"
    assert_selector("button", text: "Update", wait: 5)
    click_button "Update", match: :first

    screenshot_path = ENV.fetch("SCREENSHOT_PATH", "issue21/after.png")
    FileUtils.mkdir_p(File.dirname(screenshot_path))
    save_screenshot(screenshot_path)

    assert_current_path return_to if use_return_to
  end
end
