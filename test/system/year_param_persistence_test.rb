require "application_system_test_case"

class YearParamPersistenceTest < ApplicationSystemTestCase
  test "year selection persists across navigation" do
    prior_year = Date.current.year - 1
    Budget.create!(
      category: categories(:expense),
      year: prior_year,
      budgeted_amount: 100_00
    )

    visit root_url(year: prior_year)
    click_link "Budgets"
    take_screenshot

    assert_current_path budgets_path(year: prior_year)
    assert_selector "select[name='year'] option[selected]", text: prior_year.to_s
  end
end
