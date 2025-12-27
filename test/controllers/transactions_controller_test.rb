require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  test "create manual transaction" do
    category = categories(:expense)
    assert_difference('Transaction.count') do
      post transactions_url, params: {
        transaction: {
          category_id: category.id,
          date: Date.today,
          description: "Lunch",
          amount_dollars: "10.00"
        }
      }
    end

    transaction = Transaction.last
    assert_equal "Manual", transaction.import_source
  end

  test "create goal contribution transaction" do
    category = categories(:expense)
    assert_difference('Transaction.count') do
      post transactions_url, params: {
        transaction: {
          category_id: category.id,
          date: Date.today,
          description: "Contribution to Vacation Goal",
          amount_dollars: "100.00"
        }
      }
    end

    transaction = Transaction.last
    assert_equal "Goal Contribution", transaction.import_source
  end

  test "import transactions with service name" do
    category = categories(:expense)
    transaction_data = {
      unique_id: "123",
      date: Date.today,
      amount: 1000,
      description: "Imported Item",
      category: { name: category.name, category_type: category.category_type },
      status: "new"
    }.to_json

    assert_difference('Transaction.count') do
      post import_transactions_url, params: {
        selected_transactions: [transaction_data],
        "transaction_category_123" => category.name,
        import_service: "My Bank"
      }
    end

    transaction = Transaction.last
    assert_equal "My Bank", transaction.import_source
  end

  test "should filter transactions by source" do
    manual_transaction = Transaction.create!(
      category: categories(:expense),
      date: Date.today,
      description: "Manual Transaction",
      amount: 1000,
      import_source: "Manual"
    )

    imported_transaction = Transaction.create!(
      category: categories(:expense),
      date: Date.today,
      description: "Imported Transaction",
      amount: 2000,
      import_source: "My Bank"
    )

    get transactions_url, params: { source: "Manual" }
    assert_response :success
    assert_select "td", text: "Manual Transaction"
    assert_select "td", text: "Imported Transaction", count: 0

    get transactions_url, params: { source: "My Bank" }
    assert_response :success
    assert_select "td", text: "Imported Transaction"
    assert_select "td", text: "Manual Transaction", count: 0
  end
end