require "test_helper"

class Tools::CalculatorsControllerTest < ActionDispatch::IntegrationTest
  test "shows amortization calculator" do
    get amortization_calculator_url

    assert_response :success
    assert_select "h2", text: "Amortization Calculator"
  end

  test "shows investment calculator" do
    get investment_calculator_url

    assert_response :success
    assert_select "h2", text: "Investment Goal Calculator"
  end
end
