require "application_system_test_case"
require "fileutils"

class ProgressSortTest < ApplicationSystemTestCase
  test "dashboard sorts goals and loans by completion percent" do
    LoanPayment.delete_all
    Transaction.delete_all
    Budget.delete_all
    Loan.delete_all
    Goal.delete_all
    Category.delete_all

    goal_cat_a = Category.create!(name: "Vacation", category_type: :savings)
    goal_cat_b = Category.create!(name: "Emergency", category_type: :savings)
    goal_cat_c = Category.create!(name: "Wedding", category_type: :savings)
    goal_cat_d = Category.create!(name: "New Car", category_type: :savings)

    goal_a = Goal.create!(goal_name: "Beach", category: goal_cat_a, amount: 10_000)
    goal_b = Goal.create!(goal_name: "Rainy Day", category: goal_cat_b, amount: 10_000)
    goal_c = Goal.create!(goal_name: "Ceremony", category: goal_cat_c, amount: 10_000, archived_at: 1.day.ago)
    goal_d = Goal.create!(goal_name: "Sedan", category: goal_cat_d, amount: 10_000, archived_at: 2.days.ago)

    Transaction.create!(category: goal_cat_a, amount: 3_000, date: Date.current, description: "Goal contribution")
    Transaction.create!(category: goal_cat_b, amount: 7_000, date: Date.current, description: "Goal contribution")
    Transaction.create!(category: goal_cat_c, amount: 1_000, date: Date.current, description: "Goal contribution")
    Transaction.create!(category: goal_cat_d, amount: 9_000, date: Date.current, description: "Goal contribution")

    loan_cat_a = Category.create!(name: "Auto Loan", category_type: :expense)
    loan_cat_b = Category.create!(name: "Student Loan", category_type: :expense)
    loan_cat_c = Category.create!(name: "Paid Loan", category_type: :expense)

    loan_a = Loan.create!(loan_name: "Auto", category: loan_cat_a, balance: 8_000)
    loan_b = Loan.create!(loan_name: "Student", category: loan_cat_b, balance: 4_000)
    loan_c = Loan.create!(loan_name: "Paid", category: loan_cat_c, balance: 0)

    LoanPayment.create!(loan: loan_a, paid_amount: 2_000, interest_amount: 0, payment_date: Date.current)
    LoanPayment.create!(loan: loan_b, paid_amount: 6_000, interest_amount: 0, payment_date: Date.current)
    LoanPayment.create!(loan: loan_c, paid_amount: 1_000, interest_amount: 0, payment_date: Date.current)

    visit root_path

    goals_card = find("h5.card-title", text: "Goals").find(:xpath, "./ancestor::div[contains(concat(' ', normalize-space(@class), ' '), ' card ')][1]")
    loans_card = find("h5.card-title", text: "Loans").find(:xpath, "./ancestor::div[contains(concat(' ', normalize-space(@class), ' '), ' card ')][1]")

    FileUtils.mkdir_p("tmp/screenshots")

    page.execute_script("arguments[0].scrollIntoView({block: 'center'});", loans_card)
    page.save_screenshot("tmp/screenshots/dashboard-loans-progress-sort.png")

    page.execute_script("arguments[0].scrollIntoView({block: 'center'});", goals_card)
    page.save_screenshot("tmp/screenshots/dashboard-goals-progress-sort.png")

    page.execute_script(<<~JS, goals_card)
      window.__goals_sections = (function(card) {
        var rows = Array.from(card.querySelectorAll('tr'));
        var result = { active: [], archived: [] };
        var section = null;
        rows.forEach(function(row) {
          var text = row.textContent.toLowerCase();
          if (text.includes('active goals')) {
            section = 'active';
            return;
          }
          if (text.includes('archived goals')) {
            section = 'archived';
            return;
          }
          var nameNode = row.querySelector('td span');
          var name = nameNode && nameNode.textContent && nameNode.textContent.trim();
          if (!name) return;
          if (section === 'active') result.active.push(name);
          if (section === 'archived') result.archived.push(name);
        });
        return result;
      })(arguments[0]);
    JS

    page.execute_script(<<~JS, loans_card)
      window.__loans_sections = (function(card) {
        var rows = Array.from(card.querySelectorAll('tr'));
        var result = { active: [], paidOff: [] };
        var section = null;
        rows.forEach(function(row) {
          var text = row.textContent.toLowerCase();
          if (text.includes('active loans')) {
            section = 'active';
            return;
          }
          if (text.includes('paid off loans')) {
            section = 'paidOff';
            return;
          }
          var nameNode = row.querySelector('td span');
          var name = nameNode && nameNode.textContent && nameNode.textContent.trim();
          if (!name) return;
          if (section === 'active') result.active.push(name);
          if (section === 'paidOff') result.paidOff.push(name);
        });
        return result;
      })(arguments[0]);
    JS

    goals_sections = page.evaluate_script("window.__goals_sections")
    loans_sections = page.evaluate_script("window.__loans_sections")

    expected_active = [goal_b, goal_a].sort_by { |g| -g.percent_complete }.map(&:goal_name)
    expected_archived = [goal_d, goal_c].sort_by { |g| -g.percent_complete }.map(&:goal_name)

    expected_active_loans = [loan_b, loan_a].sort_by { |l| -l.percent_complete }.map(&:loan_name)
    expected_paid_off = [loan_c].map(&:loan_name)

    assert_equal expected_active, goals_sections["active"]
    assert_equal expected_archived, goals_sections["archived"]
    assert_equal expected_active_loans, loans_sections["active"]
    assert_equal expected_paid_off, loans_sections["paidOff"]
  end
end
