# Observability Guide

Conventions for logging, health checks, metrics, and tracing across all applications.

## Principles

1. **Observable by default** — Every app should emit logs, health checks, and (ideally) metrics from day one
2. **Structured logging** — Use JSON or key-value structured logs, not free-text
3. **Correlation** — Trace IDs should flow across service boundaries
4. **Don't log secrets** — Never log passwords, tokens, PII, or credentials

## Logging

### Log Levels

Use consistent log levels across all apps:

| Level | When to Use | Example |
| --- | --- | --- |
| `error` | Something failed and needs attention | DB connection lost, unhandled exception |
| `warn` | Something unexpected but handled | Rate limit approaching, retry succeeded |
| `info` | Normal operations worth recording | Request handled, job completed, app started |
| `debug` | Detailed diagnostic info | SQL queries, HTTP request/response bodies |

### Structured Format

Prefer structured (JSON) logging over plain text:

```json
{
  "timestamp": "2026-04-18T12:00:00Z",
  "level": "info",
  "message": "Request handled",
  "service": "api",
  "traceId": "abc123",
  "method": "GET",
  "path": "/users/42",
  "statusCode": 200,
  "durationMs": 45
}
```

### Environment-Specific Levels

| Environment | Default Level |
| --- | --- |
| Development | `debug` |
| Staging | `info` |
| Production | `info` (or `warn`) |

Configure via the `LOG_LEVEL` environment variable.

## Health Checks

Every app should expose health check endpoints:

| Endpoint | Purpose | Response |
| --- | --- | --- |
| `GET /health` | Liveness — is the process running? | `200 OK` (always, if process is alive) |
| `GET /health/ready` | Readiness — can it serve traffic? | `200` if ready, `503` if not |

### Readiness Check

Should verify critical dependencies:
- Database connection
- Cache connection
- Required external services

```json
// GET /health/ready — 200 OK
{
  "status": "healthy",
  "checks": {
    "database": "ok",
    "redis": "ok"
  }
}

// GET /health/ready — 503 Service Unavailable
{
  "status": "unhealthy",
  "checks": {
    "database": "ok",
    "redis": "failed"
  }
}
```

### Docker Compose Health Checks

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
```

### Kubernetes Probes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  periodSeconds: 30
readinessProbe:
  httpGet:
    path: /health/ready
    port: 3000
  periodSeconds: 10
```

## Metrics

Use standard metric types to monitor application behavior:

| Type | Use Case | Example |
| --- | --- | --- |
| Counter | Totals that only go up | `http_requests_total`, `errors_total` |
| Gauge | Values that go up and down | `active_connections`, `queue_depth` |
| Histogram | Distribution of values | `request_duration_seconds`, `response_size_bytes` |

### Recommended Metrics

- `http_requests_total` — by method, path, status code
- `http_request_duration_seconds` — by method, path
- `db_query_duration_seconds` — by operation
- `app_info` — gauge with version/commit labels

### Exposition

Expose metrics on a `/metrics` endpoint (Prometheus format) or push to an OTLP collector.

## Distributed Tracing

For services that communicate with each other, use distributed tracing to follow requests across boundaries.

### OpenTelemetry

[OpenTelemetry](https://opentelemetry.io/) is the industry standard. It supports all major languages and backends.

```
# .env
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
OTEL_SERVICE_NAME=api
```

### Trace Context Propagation

Ensure trace context headers (`traceparent`, `tracestate`) are propagated:
- Between HTTP services (via headers)
- Into message queues (via message attributes)
- Into logs (via trace ID field)

## Docker Compose — Local Observability Stack

Add an optional observability stack for local development:

```yaml
# infra/docker/docker-compose.observability.yml
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"   # Jaeger UI
      - "4317:4317"     # OTLP gRPC
      - "4318:4318"     # OTLP HTTP

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

## Alerting

Production environments should have alerts for:

- Error rate spike (e.g., >5% 5xx in 5 minutes)
- Latency increase (e.g., p99 > 2s)
- Health check failures
- Resource exhaustion (CPU, memory, disk)
- Certificate expiry

Configure alerts in your monitoring platform (Grafana, Azure Monitor, CloudWatch, PagerDuty, etc.).
