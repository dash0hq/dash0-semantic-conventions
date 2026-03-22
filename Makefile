.PHONY: check resolve test test-valid test-invalid generate-docs serve-docs

## Validate the registry model.
check:
	@.github/scripts/check.sh

## Resolve the full registry (including OTel dependencies).
resolve:
	@.github/scripts/resolve.sh

## Run all live-check tests.
test: test-valid test-invalid

## Run valid live-check tests (each file must pass).
test-valid:
	@.github/scripts/run-live-check-tests.sh valid

## Run invalid live-check tests (each file must be rejected).
test-invalid:
	@.github/scripts/run-live-check-tests.sh invalid

## Generate the documentation site from the model and templates.
generate-docs:
	@scripts/generate-docs.sh

## Serve the documentation site locally on port 8000.
serve-docs: generate-docs
	@echo "Serving docs at http://localhost:8000"
	@cd docs && python3 -m http.server 8000
