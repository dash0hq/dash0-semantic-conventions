# Test payloads

This directory contains [Weaver live-check](https://github.com/open-telemetry/weaver) sample payloads used to validate the registry model.

- `valid/` — Samples that **must pass** validation.
- `invalid/` — Samples that **must fail** validation.

## deployment

### Valid

| File | Description |
|------|-------------|
| `valid/deployment/full-deployment-event.json` | A `dash0.deployment` event with all supported resource and event attributes populated. |
| `valid/deployment/minimal-deployment-event.json` | A `dash0.deployment` event with only the required resource attribute (`service.name`). All optional attributes are omitted to test the baseline case. |

### Invalid

| File | Description |
|------|-------------|
| `invalid/deployment/wrong-type-service-name.json` | A `dash0.deployment` event where `service.name` has the wrong type (`int` instead of `string`). Verifies that type mismatches are rejected. |
