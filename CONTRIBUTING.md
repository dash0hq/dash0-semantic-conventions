# Contributing

## Prerequisites

- Signing the [Contributor License Agreement](https://github.com/cla-assistant/cla-assistant)
- Docker

## Making changes to the model

The semantic conventions are defined as YAML files under the `model/` directory.
They use the [OpenTelemetry Weaver](https://github.com/open-telemetry/weaver) registry format.

- `model/registry_manifest.yaml` — Registry manifest declaring dependencies (e.g., on OTel semantic conventions).
- `model/<domain>/entities.yaml` — Entity definitions.
- `model/<domain>/events.yaml` — Event definitions.

When adding or modifying conventions:

1. Edit or create the relevant YAML files under `model/`.
2. Run `make check` to validate the model.
3. Add or update test data under `tests/`.
4. Run `make test` to verify all test data.

## Test data

Test data lives under the `tests/` directory as plain JSON files:

- `tests/valid/` — Samples that must pass validation.
- `tests/invalid/` — Samples that must fail validation.

When adding a new event or entity, add at least one valid and one invalid test case.

## Validating locally

All validation runs via Docker through the provided `Makefile`.

Check the registry model for correctness:

```sh
make check
```

Resolve the full registry (including OTel dependencies) into `resolved.json`:

```sh
make resolve
```

Run all live-check tests (valid and invalid):

```sh
make test
```

You can also run only the valid or invalid suite:

```sh
make test-valid
make test-invalid
```

## Previewing the documentation site

Generate the documentation from the model and templates, then serve it locally:

```sh
make serve-docs
```

This regenerates the Markdown files in `docs/` and starts a local server at `http://localhost:8000`.
To regenerate without serving:

```sh
make generate-docs
```

## Pull requests

All pull requests are validated in CI, which runs:

1. `weaver registry check` — model validation
2. `weaver registry resolve` — full registry resolution
3. Live-check tests against all files in `tests/valid/` and `tests/invalid/`

Please make sure all checks pass locally before opening a PR.
