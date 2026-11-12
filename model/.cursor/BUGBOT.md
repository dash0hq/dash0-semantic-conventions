# Bugbot review rules for the semantic convention model

Bugbot loads this file for every change under `model/`.
These YAML files are the source of truth for the attributes, metrics, events, and entities in the Dash0 registry, and the documentation published on [docs.dash0.com](https://docs.dash0.com) is generated from them.
Review for design and semantic quality.

Flag violations of the guidance below with a short rationale and a link to the rule.
Do not flag code that was not changed in the pull request.
An empty review is better than a noisy one.

## Provenance

The sections from "File formats" to "Error handling" are adapted from the OpenTelemetry [semantic convention model review instructions](https://github.com/open-telemetry/semantic-conventions/blob/fd417dfe5a852dd7faa5106177e02450613f5552/.github/instructions/model-yaml.instructions.md) at commit `fd417df`, licensed under the [Apache License 2.0](https://github.com/open-telemetry/semantic-conventions/blob/main/LICENSE).
Changes from the original:

- Repository-relative links point to the upstream documentation.
- The list of checks CI enforces matches this repository, which does not run the upstream policy packages.
- The "Dash0 registry" section is new.

Run `scripts/check-upstream-review-guide.sh` to list upstream changes since the pinned commit.

## What CI already checks

`make check`, `make resolve`, and `make test` run on every pull request.
Do not comment on what they enforce:

- Schema validity of every file, for both definition formats.
- The annotation allowlist in `policies/annotations.rego`.
- Resolution of the registry together with its OpenTelemetry dependency.
- The live-check samples under `tests/valid/` and `tests/invalid/`.
- Coverage of every generated documentation page by the website sync configuration under `.github/workflows/sync-docs/`.

CI does **not** run the upstream naming, stability, and backward-compatibility policies, so review these yourself:

- Name format: lowercase, dot-separated namespaces, `snake_case` within a component.
- Collisions between attribute, metric, and event names, and between a name and a namespace (for example, `dash0.foo` as an attribute next to `dash0.foo.bar`).
- Removed attributes, metrics, or enum members that were already released; deprecate them instead.
- `deprecated.renamed_to` pointing to a name that exists and has the same type.
- A stable signal referencing a less stable attribute that is not `opt_in`.
- A missing `brief`, and a metric `brief` that does not end with a full stop.

## File formats

Two definition formats are valid: files starting with `file_format: definition/2` follow [schema v2](https://github.com/open-telemetry/weaver/blob/main/schemas/semconv.schema.v2.json), and all others follow [v1](https://github.com/open-telemetry/weaver/blob/main/schemas/semconv-syntax.md).
CI validates the schema.
Review only the design and semantics described below.

## New attributes

Follow [defining attributes](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/how-to-write-conventions/README.md#defining-attributes).

- Prefer reusing an existing attribute, including upstream OpenTelemetry ones; a new one needs a clear end-user benefit and a plan to emit it.
  See [common attributes](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/general/attributes.md).
- Confirm each new attribute is referenced by a signal; flag unused ones.
- New attributes should start at `development` stability.
- `brief` and `note` should clearly explain the attribute and link to standards (RFCs, specifications) when relevant.
- If a value may contain PII or other sensitive data, `note` should include a `> [!WARNING]` callout.

## Attribute type choices

See the [type syntax](https://github.com/open-telemetry/weaver/blob/main/schemas/semconv-syntax.md#type).

- Use `enum` for short, well-known value sets, and ISO 8601 strings for timestamps.
- Arrays should be homogeneous and represent one concept; split distinct concepts into separate attributes (for example, `geo.lat` and `geo.lon`, not one array).
- Use `template[...]` only for dynamic names, and only the last segment may vary.
- Prefer flat attributes over complex or structured values.

## Spans

Follow [defining spans](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/how-to-write-conventions/README.md#defining-spans).

- Spans are for operations with a duration worth observing (for example, out-of-process calls); flag point-in-time occurrences (use events) or short in-process work.
- Flag a span duplicating an existing definition; distinct spans should differ in kind or attribute set.
- Names must be low-cardinality and follow `{action} {target}`, using values also available as attributes; flag static prefixes or raw high-cardinality values.
- Attributes should capture only the operation's own important details.
- For status, reference [recording errors](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/general/recording-errors.md); avoid strict rules for ambiguous cases (cancellations, 404s).

## Metrics

Follow the [metrics general guidelines](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/general/metrics.md).

- Check that the instrument type fits the measurement (`counter`, `updowncounter`, `gauge`, `histogram`).
- `unit` should follow [UCUM](https://ucum.org/ucum): `1` for utilization, `s` for durations, non-prefixed units (`By`, not `MiBy`), and `{request}`-style annotations for counts; do not repeat the unit in the metric name.
- Metric attributes must be low-cardinality unless `opt_in`; flag unbounded values (IDs, URLs, user input) as non-`opt_in` attributes.
- For an `updowncounter`, increments and decrements must use the same attribute set.

## Events

Follow [events](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/general/events.md).

- Events are for named point-in-time occurrences; flag events for operations with a duration (use a span) or for whole-operation properties (use span attributes).
- `name` must uniquely identify the event and MUST NOT contain dynamic values.
- Do not define severity text, `body` (beyond a display message), or `ObservedTimestamp`.
- Reuse attributes shared with related signals; include `error.type` for failure or outcome events.

## Entities

Follow [resources and entities](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/how-to-write-conventions/resource-and-entities.md).

- A new entity is warranted when a signal needs a source and none fits; prefer an "is-a" relationship across domains (for example, `k8s.container` is a `container`).
- Extend an entity with descriptive attributes only when it cannot own telemetry itself (for example, `docker.container` reports against `container`).
- Each attribute must set `role: identifying` or `role: descriptive`.
- Identifying attributes should be minimally sufficient, immutable for the entity's lifespan, and resolvable consistently by multiple observers.

## Error handling

Follow [recording errors](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/general/recording-errors.md).

- Operations that can fail should populate `error.type`, with consistent values across the spans and metrics for the same operation.

## Dash0 registry

These rules are specific to this repository.
Where they differ from the upstream guidance above, they win.

### Naming

- New attributes and metrics use the `dash0.` prefix.
  `otel.*` is reserved by OpenTelemetry; the existing `otel.*` attributes in `model/registry/otel-field-attributes.yaml` map OTLP fields to queryable attributes and are a deliberate exception, so flag only new ones.
- Metric names do not end in `_total`, `_seconds`, `_bytes`, or any other unit suffix.
  Only deprecated Prometheus aliases may (see below).
- Count units use a singular annotation: `{event}`, not `{events}`.
  A counter of discrete things never uses the unit `1`.

### Descriptions

- `brief` says what the attribute holds or what the metric measures, and does not restate the name.
- For a metric, `note` says exactly what is counted or recorded, and when.
- The model is public: flag internal implementation details in `brief` or `note`, such as service or table names, internal ticket references, customer-specific behavior, or how a value is computed internally beyond what a user needs to read it.
- Flag claims about behavior that the pull request does not substantiate, especially about sampling, aggregation windows, and thresholds; ask the author for the source.
- Prose follows the rules in `CLAUDE.md`: one sentence per line, American spelling, sentences end with a full stop, the Oxford comma, and numbers as digits with "percent" spelled out.

### Synthetic metrics and Prometheus aliases

- A synthetic metric declares its source in the first line of `note`, for example `[synthetic: spans, resources]`, and does **not** declare attributes; its attributes are materialized dynamically through PromQL aggregations.
  Do not ask for attributes on these metrics.
- A metric with a legacy Prometheus name has a separate group for the alias, with `deprecated: { reason: renamed, renamed_to: <otel_name> }` and the same `instrument` and `unit` as the canonical metric.
  The canonical metric's `note` lists the alias, for example "Deprecated PromQL alias: `dash0_spans_total`.".
  Flag a new alias without its canonical metric, or a canonical metric whose `note` does not list its aliases.
- `dash0.check.status` and `dash0.issue.status` are gauges that encode a state as a number; this is live product behavior.
  Do not suggest converting them, but flag new metrics that copy the pattern instead of using an `updowncounter` with one series per state.

### Annotations

- New annotation namespaces, keys, or values must be added to the allowlist in `policies/annotations.rego` and documented in `CONTRIBUTING.md` in the same pull request.

### Changes outside `model/` that must accompany a model change

- `README.md`: the "Conventions" section lists every attribute by its full name, one bullet per event, and the canonical metric names per functional area, without deprecated aliases.
  Flag an added, removed, or renamed attribute, metric, or event that is not reflected there.
- `tests/`: a new event or entity needs at least one valid and one invalid sample, and every test file needs a row in `tests/README.md`.
