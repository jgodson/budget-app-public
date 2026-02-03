require "application_system_test_case"

class AmortizationCalculatorTest < ApplicationSystemTestCase
  test "renders amortization calculator and captures screenshot" do
    visit amortization_calculator_path

    select Loan.first.loan_name, from: "amortization-loan-select"

    fill_in("amortization-amount", with: "250000")
    fill_in("amortization-rate", with: "6.25")
    fill_in("amortization-term-years", with: "30")
    fill_in("amortization-term-months", with: "0")
    fill_in("amortization-payment", with: "")
    fill_in("amortization-start-date", with: "2026-01-01")

    fill_in("amortization-extra-monthly-amount", with: "150")
    set_hidden_value("#amortization-extra-monthly-start", "2026-06")

    click_on "Add"
    set_hidden_value(all(".one-time-date", visible: :all).last, "2027-01")
    all(".one-time-amount", visible: :all).last.set("2000")

    assert_selector "canvas"

    take_screenshot
  end

  private

  def set_hidden_value(selector_or_element, value)
    element =
      if selector_or_element.respond_to?(:tag_name)
        selector_or_element
      else
        first(:css, "#{selector_or_element}[type='hidden']", visible: :all) ||
          first(:css, selector_or_element, visible: :all)
      end
    raise Capybara::ElementNotFound, "Unable to find element for #{selector_or_element.inspect}" unless element
    execute_script(
      "arguments[0].value = arguments[1]; arguments[0].dispatchEvent(new Event('change', { bubbles: true }));",
      element,
      value
    )
  end
end
