require "application_system_test_case"
require "fileutils"

class CategoriesSortTest < ApplicationSystemTestCase
  test "categories and subcategories are sorted alphabetically" do
    LoanPayment.delete_all
    Transaction.delete_all
    Budget.delete_all
    Loan.delete_all
    Goal.delete_all
    Category.delete_all

    parent = Category.create!(name: "Utilities", category_type: :expense)
    Category.create!(name: "Auto", category_type: :expense)
    Category.create!(name: "Groceries", category_type: :expense)
    Category.create!(name: "Flights", category_type: :expense)

    Category.create!(name: "Water", category_type: :expense, parent_category: parent)
    Category.create!(name: "Electric", category_type: :expense, parent_category: parent)

    visit categories_path

    FileUtils.mkdir_p("tmp/screenshots")
    page.save_screenshot("tmp/screenshots/categories-index.png")

    base_names = all("tr[data-controller='clickable-row'] td:first-child").map do |cell|
      next if cell[:class].to_s.include?("pl-4")

      cell.text.strip
    end.compact

    subcategory_names = all("tr[data-controller='clickable-row'] td:first-child.pl-4").map do |cell|
      cell.text.strip
    end

    assert_equal base_names.sort, base_names
    assert_equal subcategory_names.sort, subcategory_names
  end
end
