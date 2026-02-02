require "test_helper"

class LoansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @loan = loans(:car_loan)
  end

  test "should get index" do
    get loans_url
    assert_response :success
  end

  test "should get new" do
    get new_loan_url
    assert_response :success
  end

  test "should get edit" do
    get edit_loan_url(@loan)
    assert_response :success
  end

  test "show respects year param in charts" do
    get loan_url(@loan, year: 2020)
    assert_response :success
    assert_includes response.body, "2020 Total"
    assert_includes response.body, "2019 Total"
  end
end
