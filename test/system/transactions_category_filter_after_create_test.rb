require "application_system_test_case"
require "fileutils"

class TransactionsCategoryFilterAfterCreateTest < ApplicationSystemTestCase
  test "creating a transaction returns to the list filtered by category" do
    category = categories(:expense)

    return_to = transactions_path
    visit new_transaction_path(return_to: return_to)

    category_select = find("select#transaction_category_id_select", visible: false)
    page.execute_script(
      "arguments[0].value = arguments[1]; arguments[0].dispatchEvent(new Event('change', { bubbles: true }));",
      category_select,
      category.id.to_s,
    )
    fill_in "Date", with: Date.current.strftime("%Y-%m-%d")
    fill_in "Description", with: "Filtered category entry"
    fill_in "Amount", with: "12.34"
    click_button "Create", match: :first

    screenshot_path = ENV.fetch("SCREENSHOT_PATH", "issue15/after.png")
    FileUtils.mkdir_p(File.dirname(screenshot_path))
    save_screenshot(screenshot_path)

    expect_filter = ENV.fetch("EXPECT_CATEGORY_FILTER", "true") != "false"
    if expect_filter
      assert_current_path transactions_path(category: category.id, year: Date.current.year)
      category_filter = find("select#category_filter_select", visible: false)
      assert_equal category.id.to_s, category_filter.value
    end
  end
end
