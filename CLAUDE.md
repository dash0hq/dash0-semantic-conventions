# CLAUDE.md — Dash0 Semantic Conventions

## Project overview

This repository defines Dash0's semantic conventions using the [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver) registry format.
It builds on top of the [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/).

## Repository structure

```
model/
  registry_manifest.yaml          # Registry manifest with OTel semconv dependency
  <namespace>                     # Different folders, organize by functional area
tests/
  valid/                          # JSON5 test data expected to pass validation
  invalid/                        # JSON5 test data expected to fail validation
```

## Validation

Validate the registry model using dockerized Weaver:

```sh
docker run --rm -v "$(pwd)/model:/model" fa4f1c6954ec registry check -r /model
```

Or if Weaver is installed locally:

```sh
weaver registry check -r ./model
```

## Metric documentation workflow

The metric definitions were produced by:

1. **Discovery** — Using the Dash0 MCP server (`mcp__dash0-dev__getMetricCatalog` and `mcp__dash0-dev__getMetricDetails`) to enumerate all metrics in the `dash0` namespace.
2. **Cross-referencing** — Checking metric names, instruments, and units against the Dash0 backend source code (e.g., `modules/backend-utils/pkg/common/constants.go` and `components/api/internal/retrieval/metricretrieval/metriccatalog.go` in the `dash0` monorepo).
3. **Modeling** — Writing Weaver-format YAML metric groups with `type: metric`, `instrument`, `unit`, `brief`, and `note` fields.
4. **Validation** — Running `weaver registry check` to ensure all definitions pass schema validation.

### Key conventions

- Synthetic metrics (scope `dash0.metric.synthetic`) do **not** declare attributes. Attributes are materialised dynamically through PromQL aggregations.
- Deprecated Prometheus aliases (e.g., `dash0_spans_total`) get their own metric group entry with `deprecated: { reason: renamed, renamed_to: <otel_name> }`.
- Every metric **must** have a `unit` field compliant with [UCUM](https://ucum.org/).

## Prose rules

Follow these rules when writing or editing prose in this project.

- **One sentence per line** (semantic line breaks).
  Each sentence starts on its own line; do not wrap mid-sentence.
- Separate paragraphs with a single blank line.
- Section headers use sentence case (e.g., "Key conventions").
- Use inline Markdown links: `[visible text](url)`.
  Link the most specific relevant term, not generic phrases.
- Fence code blocks with triple backticks and a language identifier (e.g., ` ```yaml `).
- End sentences with full stops.
- Use the **Oxford comma** (e.g., "spans, logs, and metrics").
- Write numbers as digits and spell out "percent" (e.g., "10 percent").

## README.md maintenance

The `Conventions` section in `README.md` is a hand-maintained summary. When adding, removing, or renaming attributes, metrics, or events in the `model/` directory, update the corresponding entry in `README.md`:

- **Attributes** — List every attribute by its full name (e.g., `dash0.resource.id`, not just `id`).
- **Events** — One bullet per event, with event name and a short description.
- **Metrics** — One bullet per functional area, listing the canonical OTel metric names. Do not list deprecated PromQL aliases.
