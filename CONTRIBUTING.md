# Contributing

## Prerequisites

- Signing the [Contributor License Agreement](https://github.com/cla-assistant/cla-assistant)
- [OTel Weaver](https://github.com/open-telemetry/weaver) (v0.21.2+)
- Node.js (LTS) — used for converting JSON5 test data

## Making changes to the model

The semantic conventions are defined as YAML files under the `model/` directory.
They use the [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver) registry format.

- `model/registry_manifest.yaml` — Registry manifest declaring dependencies (e.g., on OTel semantic conventions).
- `model/<domain>/entities.yaml` — Entity definitions.
- `model/<domain>/events.yaml` — Event definitions.

When adding or modifying conventions:

1. Edit or create the relevant YAML files under `model/`.
2. Run `weaver registry check -r ./model` to validate the model.
3. Add or update test data under `tests/`.

## Test data

Test data lives under the `tests/` directory as [JSON5](https://json5.org/) files:

- `tests/valid/` — Samples that must pass validation.
- `tests/invalid/` — Samples that must fail validation.

When adding a new event or entity, add at least one valid and one invalid test case.

## Validating locally

Check the registry model for correctness:

```sh
weaver registry check -r ./model
```

Resolve the full registry (including OTel dependencies):

```sh
weaver registry resolve -r ./model -o resolved.json
```

Run the live-check tests against valid test data:

```sh
for file in $(find tests/valid -name '*.json5' | sort); do
  tmpfile=$(mktemp --suffix=.json)
  npx json5 "$file" > "$tmpfile"
  weaver registry live-check -r ./model --input-source "$tmpfile" --input-format json
  rm "$tmpfile"
done
```

Run the live-check tests against invalid test data (each file should be rejected):

```sh
for file in $(find tests/invalid -name '*.json5' | sort); do
  tmpfile=$(mktemp --suffix=.json)
  npx json5 "$file" > "$tmpfile"
  weaver registry live-check -r ./model --input-source "$tmpfile" --input-format json
  rm "$tmpfile"
done
```

## Pull requests

All pull requests are validated in CI, which runs:

1. `weaver registry check` — model validation
2. `weaver registry resolve` — full registry resolution
3. Live-check tests against all files in `tests/valid/` and `tests/invalid/`

Please make sure all checks pass locally before opening a PR.
