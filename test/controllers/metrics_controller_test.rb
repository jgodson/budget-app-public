require 'test_helper'

class MetricsControllerTest < ActionDispatch::IntegrationTest
  test 'should get metrics endpoint' do
    get metrics_url

    assert_response :success
    assert_match %r{text/plain}, response.content_type
    assert_match(/http_request_duration_seconds/, response.body)
  end
end
