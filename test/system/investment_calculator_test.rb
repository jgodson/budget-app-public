require "application_system_test_case"

class InvestmentCalculatorTest < ApplicationSystemTestCase
  test "calculates investment goal projection" do
    visit investment_calculator_path

    select "Emergency Fund Goal", from: "investment_goal_id"

    assert_field "goal-amount", with: "10,000.00"
    assert_field "initial-investment", with: "2,400.00"
    assert_field "contribution-amount", with: "200.00"

    fill_in("contribution-amount", with: "250")
    fill_in("annual-return", with: "6")
    assert_selector "[data-investment-calculator-target='goalStatusLabel']", text: "GOAL REACHED (ESTIMATED)"
    assert_selector "canvas:not(.d-none)"

    take_screenshot
  end
end
