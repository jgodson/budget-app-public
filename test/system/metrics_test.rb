require "application_system_test_case"

class MetricsTest < ApplicationSystemTestCase
  test "metrics endpoint renders prometheus text" do
    visit dashboard_url
    visit metrics_url

    assert_text "http_request_duration_seconds"
    take_screenshot
  end
end
