# Prometheus Metrics

This document describes the available Prometheus metrics exposed by the `/metrics` endpoint.

## Available Metrics

### `http_request_duration_seconds`

A histogram metric measuring HTTP request duration in seconds.

**Labels:**
- `controller`: The Rails controller handling the request
- `action`: The controller action method
- `method`: The HTTP method (GET, POST, PUT, DELETE, etc.)
- `status`: The HTTP status code returned (200, 404, 500, etc.)

**Description:**
This histogram tracks the time taken to process each HTTP request in the Rails application. It provides:
- Request count (via the histogram's `_count` metric)
- Request duration distribution (via `_sum`, `_bucket` metrics)
- Duration percentiles (p50, p90, p95, p99)

**Use Cases:**
- Monitor application response times
- Identify slow endpoints or controllers
- Alert on degraded performance
- Track error rates via status code labels

**Example PromQL Query:**

Average request duration by controller:
```promql
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

Request rate by controller and action:
```promql
rate(http_request_duration_seconds_count[5m])
```

95th percentile request duration:
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

Error rate (non-2xx responses):
```promql
rate(http_request_duration_seconds_count{status=~"4..|5.."}[5m])
```

## Accessing Metrics

The metrics endpoint is available at:
```
http://localhost:3000/metrics
```

This endpoint exposes metrics in Prometheus text format for scraping by Prometheus or compatible monitoring systems.

**Note:** This endpoint is not secured and should only be exposed within trusted networks (e.g., a private homelab network).
