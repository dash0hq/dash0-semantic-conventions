# Requirements: Sync Dash0 Public Semantic Conventions to the Dash0 Website

**Date:** 2026-08-05  
**Status:** Ready for implementation

---

## Goal

Publish the `dash0-public` semantic conventions to [docs.dash0.com](https://docs.dash0.com) so customers can discover and reference `dash0.*` attribute names, metrics, and events without leaving the main Dash0 documentation.

---

## Background

`dash0hq/dash0-semantic-conventions` already generates full Weaver-rendered markdown and deploys it to GitHub Pages (`dash0hq.github.io/dash0-semantic-conventions/`). That site **remains live** as a showcase of how to work with Weaver. The website sync is an additional destination, not a replacement.

The existing `release.yml` workflow already:
1. Checks out the repo and installs Weaver
2. Runs `scripts/generate-docs.sh` → markdown output into `docs/` (gitignored)
3. Deploys `docs/` to GitHub Pages

The new work adds a fourth step in `release.yml`: sync the generated markdown to `dash0hq/dash0-website` via `dash0hq/sync-docs-action`. **No changes to `dash0hq/dash0`.**

The website already has semantic convention pages at some location under the OpenTelemetry section. Those existing pages must be updated (redirected or refurbished) to point to the new synced location.

There is a `dash0-sync-docs` Claude Code skill for this action, installed via:
```shell
/plugin marketplace add dash0hq/sync-docs-action
/plugin install dash0-sync-docs@dash0-sync-docs-action
```
Use it when implementing the `transformations.yaml` and the workflow wiring.

---

## Scope

### In scope

- **Repository:** `dash0hq/dash0-semantic-conventions` for the sync workflow and templates. `dash0hq/dash0-website` for refurbishing existing semconv pages.
- **Conventions:** `dash0-public` registry only. `dash0-internal` conventions are never published publicly.
- **Trigger:** On release (tag push `v*`), same trigger as the existing GitHub Pages deploy — Approach C: extend `release.yml` directly.
- **Dry-run:** `validate-pr.yml` gains a dry-run invocation so coverage failures are caught on every PR build, not only at release time.

### Out of scope

- Retiring the GitHub Pages site (it stays as a Weaver showcase).
- Publishing `dash0-internal` conventions publicly.
- Graduating conventions from `weaver/dash0-internal` (monorepo) to `dash0-semantic-conventions` — tracked as a follow-up.
- Changes to code generation (`modules/semconv`) or the generated language constants.

---

## Requirements

### R1 — Extend `release.yml` with a sync step

After the existing "Deploy to GitHub Pages" step, `release.yml` invokes `dash0hq/sync-docs-action` with:

- `source-root`: the generated `docs/` directory (Weaver wrote it in the prior step)
- `transformations-file`: `.github/workflows/sync-docs/transformations.yaml` (new file, see R3)
- `dry-run: false`
- `target-*` inputs sourced from the three repository secrets (same names as `dash0-operator`): `DASH0_DOCS_REPO_GITHUB_PAT`, `SYNC_DOCUMENTATION_TARGET_REPOSITORY`, `SYNC_DOCUMENTATION_TARGET_DIRECTORY`
- No `pr-reviewers` (skip reviewer assignment)

### R2 — Add dry-run to `validate-pr.yml`

`validate-pr.yml` gains a job that runs the same sync step with `dry-run: true`. This catches coverage failures (new convention groups not yet wired into `transformations.yaml`) on every PR, before a release is cut. The dry-run job needs no secrets.

### R3 — Add `transformations.yaml`

A new file at `.github/workflows/sync-docs/transformations.yaml` enumerates every page Weaver generates.

**Target paths** are resolved relative to `SYNC_DOCUMENTATION_TARGET_DIRECTORY`. The full path in the website repo is `src/app/(core)/docs/content/dash0/opentelemetry/semconvs/`, so target values are of the form `dash0/opentelemetry/semconvs/<page>.md`.

**`nav:` block** — required (v0.3.0+) for the website's navigation tree. `parentPath` should reflect the position under the OpenTelemetry section; `order` should be chosen to place the semconv pages correctly within that section.

**`files:` list** — one entry per generated page. The exact set depends on what `generate-docs.sh` currently emits. Based on `weaver.yaml`:

| Generated source | Website target | Notes |
|---|---|---|
| `README.md` | `dash0/opentelemetry/semconvs/overview.md` | Landing page |
| `attributes/README.md` | `dash0/opentelemetry/semconvs/attributes/overview.md` | |
| `attributes/<namespace>.md` | `dash0/opentelemetry/semconvs/attributes/<namespace>.md` | One per namespace |
| `metrics/README.md` | `dash0/opentelemetry/semconvs/metrics/overview.md` | |
| `metrics/<group>.md` | `dash0/opentelemetry/semconvs/metrics/<group>.md` | One per metric group |
| `events/README.md` | `dash0/opentelemetry/semconvs/events/overview.md` | If events exist |
| `entities/README.md` | `dash0/opentelemetry/semconvs/entities/overview.md` | If entities exist |

**`common` transformations** — at minimum strip the leading H1 heading (frontmatter `title` replaces it) and the `<!-- NOTE: THIS FILE IS AUTOGENERATED. DO NOT EDIT BY HAND. -->` comment. Additional common transformations may be needed after reviewing rendered output against the website's expected format (see R4).

**No `coverage` block required** — the CLI's `transformations.yaml` notes that coverage enforcement was removed in `sync-docs-action` v0.2.0. The dry-run in `validate-pr.yml` (R2) provides equivalent protection via the transformation dry-run itself.

### R4 — Bespoke Weaver templates for website-targeted output

The existing `templates/registry/markdown/` templates were designed for GitHub Pages and will likely need a website-targeted variant. A new template set (e.g., `templates/registry/website/`) generates output shaped for the Dash0 website's markdown renderer and design conventions.

**Process:**
1. Inspect several existing Dash0 docs pages to understand the expected heading structure, table style, stability badge treatment, and link format.
2. Identify which elements of the current markdown output are GitHub-Pages-specific (the `index.html.j2` entry in `weaver.yaml`, the Hugo front-matter comment, any GitHub-relative links).
3. Create the new template set. The `generate-docs.sh` script (or a parallel `generate-docs-website.sh`) should be able to target either template set so both GitHub Pages and the website can be generated from a single registry run.
4. The `release.yml` step that feeds `sync-docs-action` uses the website-targeted output, not the GitHub Pages output.

Alternatively, if the current templates produce output that is already compatible with the website's renderer after the `common` transformations strip the problematic elements, a separate template set is not needed. Verify against the live website before investing in new templates.

### R5 — Secrets in `dash0-semantic-conventions` repository settings

Before the first release with this change, three secrets must exist in the repository settings (same scope as the operator's secrets — ask the team for the PAT):

| Secret | Purpose |
|---|---|
| `DASH0_DOCS_REPO_GITHUB_PAT` | Fine-grained PAT with `contents:write` + `pull-requests:write` on `dash0hq/dash0-website` |
| `SYNC_DOCUMENTATION_TARGET_REPOSITORY` | `dash0hq/dash0-website` |
| `SYNC_DOCUMENTATION_TARGET_DIRECTORY` | `src/app/(core)/docs/content/` |

### R6 — Refurbish existing semconv pages in `dash0hq/dash0-website`

The website already has semantic convention pages under the OpenTelemetry section at a location other than `src/app/(core)/docs/content/dash0/opentelemetry/semconvs/`. Those pages must be updated in the same PR (or a coordinated PR) that introduces the new synced pages:

- Existing pages that duplicate content now synced from the registry → replace with redirects to the new synced URLs.
- Existing pages that are navigation/overview pages pointing to the old location → update links to point to `dash0/opentelemetry/semconvs/`.
- Confirm no broken links remain using the website's link-checker CI.

---

## Success criteria

- On every release tag, `release.yml` completes both the GitHub Pages deploy and a `sync-docs-action` step that opens (or updates) a PR against `dash0hq/dash0-website` containing the transformed semconv pages.
- On every PR build in `dash0-semantic-conventions`, `validate-pr.yml` runs the dry-run and catches any new convention group that isn't yet wired into `transformations.yaml`.
- GitHub Pages continues to deploy unchanged from the same `release.yml` run.
- The synced pages render consistently with adjacent Dash0 docs pages (heading hierarchy, table style, stability callouts).
- Existing semconv URLs on the Dash0 website redirect cleanly to the new synced pages.

---

## Open questions

1. **Template verdict** — after inspecting the current markdown output against the website's rendered format: do existing templates need a new website variant (R4 full), or is the current output close enough that `common` transformations can bridge the gap? This is a judgment call made during implementation.
2. **Existing semconv page inventory** — the exact set of pages to redirect/refurbish in `dash0-website` is not known without reading the repo. The implementer should audit `src/app/(core)/docs/content/dash0/opentelemetry/` before writing the redirects.
