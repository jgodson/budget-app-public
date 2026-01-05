require 'prometheus'
require 'prometheus/client'

Prometheus::Client.registry

http_request_duration = Prometheus::Client::Histogram.new(
  :budget_app_http_request_duration_seconds,
  docstring: 'HTTP request duration in seconds',
  labels: %i[controller action method status]
)

begin
  Prometheus::Client.registry.register(http_request_duration)
rescue Prometheus::Client::Registry::AlreadyRegisteredError
  http_request_duration = Prometheus::Client.registry.get(:budget_app_http_request_duration_seconds)
end

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  controller = event.payload[:controller]
  action = event.payload[:action]
  method = event.payload[:method]
  status = event.payload[:status]

  next unless controller && action && method && status

  http_request_duration.observe(
    event.duration / 1000.0,
    labels: { controller: controller, action: action, method: method, status: status }
  )
end
