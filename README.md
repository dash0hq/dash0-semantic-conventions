# Dash0 Semantic Conventions

This repository contains the semantic conventions for [Dash0](https://www.dash0.com).
The conventions are defined using the [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver) registry format and build on top of the [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/).

## Conventions

### Events

- **Deployment Event** (`dash0.deployment`) — Marks the deployment of a service version to an environment. Emitted once per deployment from CI/CD pipelines (e.g., a GitHub Action).

### Metrics

- **Tracing** (`dash0.spans`, `dash0.spans.duration`, `dash0.span.events`) — Span counts, duration distributions, and span event counts.
- **Logging** (`dash0.logs`) — Log record counts.
- **Metrics** (`dash0.metrics.datapoints`) — Metric data point counts.
- **Resources** (`dash0.resources`) — Resource counts and resource-related attributes like `dash0resource.id`.
- **RED Metrics** (`dash0.spans.red`) — Pre-aggregated Rate/Error/Duration exponential histogram over spans.
- **Website Monitoring** (`dash0.web.*`) — Web events, bounces, errors, page views, requests, sessions, users, and Core Web Vitals (CLS, INP, LCP).
- **Synthetic Checks** (`dash0.synthetic_check.*`) — Synthetic check runs and HTTP timing breakdowns (DNS, connection, SSL, request, response, total duration).
- **Alerting** (`dash0.check.*`, `dash0.issue.*`) — Check status, evaluation outcomes/values, thresholds, enablement conditions, and issue status.
- **Dash0 Operator** (`dash0.operator.manager.*`) — Kubernetes operator worker pools, reconcile counts, errors, and timing.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

[Apache License 2.0](LICENSE.md)

Copyright 2026 Dash0 Inc.
