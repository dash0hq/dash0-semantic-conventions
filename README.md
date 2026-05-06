# Dash0 Semantic Conventions

This repository contains the semantic conventions for [Dash0](https://www.dash0.com).
The conventions are defined using the [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver) registry format.
They build on top of the [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/).

The full registry documentation is published at [dash0hq.github.io/dash0-semantic-conventions](https://dash0hq.github.io/dash0-semantic-conventions/).
This is a temporary location; the content will be merged into the [Dash0 Docs](https://docs.dash0.com) in a future release.

## Conventions

### Attributes

- **Resource** — Resource identity and classification: `dash0.resource.id`, `dash0.resource.hash`, `dash0.resource.name`, `dash0.resource.type`.
- **Operation** — Operation naming and typing: `dash0.operation.name`, `dash0.operation.type`.
- **Span** — Span identity: `dash0.span.name`, `dash0.span.type`.
- **Trace Origin** — Trace origin classification and context: `dash0.trace.origin.type`, `dash0.trace.origin.web.session.id`, `dash0.trace.origin.web.event.id`, `dash0.trace.origin.synthetic_check.check_id`, `dash0.trace.origin.synthetic_check.attempt_id`, `dash0.trace.origin.synthetic_check.follow_redirect`.
- **Log** — Log enrichment: `dash0.log.message`, `dash0.log.pattern`, `dash0.log.ai.attributes_inferred`, `dash0.log.ai.message_inferred`, `dash0.log.ai.severity_inferred`.
- **Span Event** — Span event conversion: `dash0.span_event.converted`.
- **OTLP Field Mappings** — Dash0-specific mappings of OTLP protocol fields to queryable attributes: `otel.trace.id`, `otel.span.id`, `otel.parent.id`, `otel.span.name`, `otel.span.kind`, `otel.span.status.code`, `otel.span.status.message`, `otel.span.event.name`, `otel.log.body`, `otel.log.severity.number`, `otel.log.severity.range`, `otel.log.severity.text`, `otel.metric.name`, `otel.metric.type`, `otel.metric.unit`, `otel.metric.overflow`.

### Events

- **Deployment Event** (`dash0.deployment`) — Marks the deployment of a service version to an environment. Emitted once per deployment from CI/CD pipelines (e.g., a GitHub Action).

### Metrics

- **Tracing** (`dash0.spans`, `dash0.spans.duration`, `dash0.span.events`) — Span counts, duration distributions, and span event counts.
- **Logging** (`dash0.logs`) — Log record counts.
- **Metrics** (`dash0.metrics.datapoints`) — Metric data point counts.
- **Resources** (`dash0.resources`) — Resource counts and resource-related attributes like `dash0.resource.id`.
- **RED Metrics** (`dash0.spans.red`) — Pre-aggregated Rate/Error/Duration exponential histogram over spans.
- **Website Monitoring** (`dash0.web.*`) — Web events, bounces, errors, page views, requests, sessions, users, and Core Web Vitals (CLS, INP, LCP).
- **GenAI** (`dash0.genai.conversation.count`, `dash0.genai.conversation.duration`, `dash0.genai.conversation.errors`) — GenAI session counts, duration distributions, and error counts.
- **Synthetic Checks** (`dash0.synthetic_check.*`) — Synthetic check runs and HTTP timing breakdowns (DNS, connection, SSL, request, response, total duration).
- **Alerting** (`dash0.check.*`, `dash0.issue.*`) — Check status, evaluation outcomes/values, and issue status.
- **Dash0 Operator** (`dash0.operator.manager.*`) — Kubernetes operator worker pools, reconcile counts, errors, and timing.