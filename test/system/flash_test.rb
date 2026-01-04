require "application_system_test_case"

class FlashTest < ApplicationSystemTestCase
  test "flash message on import error" do
    visit import_form_transactions_path
    
    click_button "Preview Import"
    
    assert_text "Please select a file to upload."
    
    take_screenshot
  end
end