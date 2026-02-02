require "application_system_test_case"

class AmortizationCalculatorTest < ApplicationSystemTestCase
  test "renders amortization calculator and captures screenshot" do
    visit amortization_calculator_path

    fill_in("amortization-amount", with: "250000")
    fill_in("amortization-rate", with: "6.25")
    fill_in("amortization-term", with: "30")
    fill_in("amortization-payment", with: "")
    fill_in("amortization-start-date", with: "2026-01-01")

    fill_in("amortization-extra-monthly-amount", with: "150")
    set_hidden_value("#amortization-extra-monthly-start", "2026-06")

    click_on "Add"
    within all(".one-time-date").last.find(:xpath, "..").find(:xpath, "..") do
      set_hidden_value(".one-time-date", "2027-01")
      find(".one-time-amount").set("2000")
    end

    assert_selector "canvas"

    take_screenshot
  end

  private

  def set_hidden_value(selector, value)
    element = first(:css, "#{selector}[type='hidden']", visible: :all) ||
      first(:css, selector, visible: :all)
    raise Capybara::ElementNotFound, "Unable to find #{selector}" unless element
    execute_script(
      "arguments[0].value = arguments[1]; arguments[0].dispatchEvent(new Event('change', { bubbles: true }));",
      element,
      value
    )
  end
end
