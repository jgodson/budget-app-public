# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

def to_cents(dollars)
  (dollars * 100).to_i
end

puts "Starting seed process..."

if ENV['CLEAN'] == 'true'
  puts "Cleaning existing data..."
  LoanPayment.destroy_all
  Transaction.destroy_all
  Budget.destroy_all
  Loan.destroy_all
  Goal.destroy_all
  Category.destroy_all
end

# 1. Create Categories
puts "Creating Categories..."
income_categories = ['Salary', 'Freelance', 'Investments', 'Gifts'].map do |name|
  Category.find_or_create_by!(name: name) do |c|
    c.category_type = :income
  end
end

expense_categories = ['Rent', 'Groceries', 'Utilities', 'Entertainment', 'Transport', 'Dining Out', 'Health', 'Shopping'].map do |name|
  Category.find_or_create_by!(name: name) do |c|
    c.category_type = :expense
  end
end

loans_category = Category.find_or_create_by!(name: 'Loans') do |c|
  c.category_type = :expense
end

savings_category = Category.find_or_create_by!(name: 'Savings') do |c|
  c.category_type = :savings
end

# 2. Determine Time Range
months_to_seed = ENV.fetch('MONTHS_TO_SEED', 1).to_i
end_date = Date.today
start_date = end_date - months_to_seed.months

puts "Generating data from #{start_date.strftime('%B %Y')} to #{end_date.strftime('%B %Y')} (#{months_to_seed} months)"

# 3. Create Loans
puts "Creating Loans..."
# Create specific categories for loans because Loan model requires unique category
car_loan_category = Category.find_or_create_by!(name: 'Car Loan Payment', parent_category: loans_category) do |c|
  c.category_type = :expense
end

car_loan = Loan.find_or_create_by!(loan_name: 'Car Loan') do |loan|
  loan.balance = to_cents(25000)
  loan.category = car_loan_category
end

student_loan_category = Category.find_or_create_by!(name: 'Student Loan Payment', parent_category: loans_category) do |c|
  c.category_type = :expense
end

student_loan = Loan.find_or_create_by!(loan_name: 'Student Loan') do |loan|
  loan.balance = to_cents(40000)
  loan.category = student_loan_category
end

# 4. Create Goals
puts "Creating Goals..."
emergency_fund_category = Category.find_or_create_by!(name: 'Emergency Fund', parent_category: savings_category) do |c|
  c.category_type = :savings
end

Goal.find_or_create_by!(goal_name: 'Emergency Fund') do |goal|
  goal.amount = to_cents(10000)
  goal.category = emergency_fund_category
end

vacation_category = Category.find_or_create_by!(name: 'Vacation', parent_category: savings_category) do |c|
  c.category_type = :savings
end

Goal.find_or_create_by!(goal_name: 'Europe Trip') do |goal|
  goal.amount = to_cents(5000)
  goal.category = vacation_category
end

new_car_category = Category.find_or_create_by!(name: 'New Car', parent_category: savings_category) do |c|
  c.category_type = :savings
end

Goal.find_or_create_by!(goal_name: 'Tesla Model 3') do |goal|
  goal.amount = to_cents(40000)
  goal.category = new_car_category
end

savings_goals_categories = [emergency_fund_category, vacation_category, new_car_category]

# 5. Loop through months
(0..months_to_seed).each do |i|
  current_month = start_date + i.months
  year = current_month.year
  month = current_month.month
  
  # Create Budgets
  expense_categories.each do |category|
    amount = case category.name
      when 'Rent' then to_cents(2000)
      when 'Groceries' then to_cents(600)
      when 'Utilities' then to_cents(200)
      when 'Entertainment' then to_cents(300)
      when 'Transport' then to_cents(150)
      when 'Dining Out' then to_cents(400)
      when 'Health' then to_cents(100)
      when 'Shopping' then to_cents(200)
      else to_cents(100)
    end
    
    Budget.find_or_create_by!(category: category, year: year, month: month) do |budget|
      budget.budgeted_amount = amount
    end
  end

  # Create Income Transactions
  Transaction.create!(
    date: Date.new(year, month, 1),
    description: "Monthly Salary",
    amount: to_cents(5000 + rand(-100..100)),
    category: income_categories.first
  )

  if [true, false].sample
    Transaction.create!(
      date: Date.new(year, month, rand(5..25)),
      description: "Freelance Project",
      amount: to_cents(rand(500..1500)),
      category: income_categories.second
    )
  end

  # Create Savings Transactions (Contributions)
  savings_goals_categories.each do |cat|
    if [true, false].sample # Randomly contribute to goals
      Transaction.create!(
        date: Date.new(year, month, rand(1..28)),
        description: "Transfer to #{cat.name}",
        amount: to_cents(rand(100..500)),
        category: cat
      )
    end
  end

  # Create Expense Transactions
  # Rent (Fixed)
  Transaction.create!(
    date: Date.new(year, month, 1),
    description: "Monthly Rent",
    amount: to_cents(2000),
    category: expense_categories.find { |c| c.name == 'Rent' }
  )

  # Other variable expenses
  rand(15..40).times do
    date = Date.new(year, month, rand(1..28))
    category = expense_categories.reject { |c| c.name == 'Rent' }.sample
    
    amount = case category.name
             when 'Groceries' then rand(50..200)
             when 'Utilities' then rand(80..150)
             when 'Entertainment' then rand(20..100)
             when 'Transport' then rand(10..50)
             when 'Dining Out' then rand(30..120)
             else rand(10..100)
             end

    Transaction.create!(
      date: date,
      description: Faker::Commerce.product_name,
      amount: to_cents(amount),
      category: category
    )
  end

  # Loan Payments
  # Car Loan
  if i > 0
    payment_date = Date.new(year, month, 15)
    amount = to_cents(450)
    interest = (car_loan.balance * 0.05 / 12).round # Simple interest approx
    
    trx = Transaction.create!(
      date: payment_date,
      description: "Car Loan Payment",
      amount: amount,
      category: car_loan.category
    )

    LoanPayment.create!(
      loan: car_loan,
      paid_amount: amount,
      interest_amount: interest,
      payment_date: payment_date,
      associated_transaction_id: trx.id
    )
  end
end

puts "Seeding completed successfully!"
