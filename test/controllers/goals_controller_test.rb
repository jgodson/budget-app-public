require "test_helper"

class GoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @goal = goals(:emergency)
  end

  test "show respects year param in charts" do
    Transaction.create!(
      category: @goal.category,
      amount: 10_000,
      date: Date.new(2022, 2, 15)
    )
    Transaction.create!(
      category: @goal.category,
      amount: 5_000,
      date: Date.new(2021, 11, 5)
    )

    get goal_url(@goal, year: 2022)
    assert_response :success
    assert_includes response.body, "2022 Contributions"
    assert_includes response.body, "2021 Contributions"
  end
end
