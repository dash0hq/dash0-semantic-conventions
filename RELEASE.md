# Release Process

Releases follow [semantic versioning](https://semver.org/) and are tagged as `v${version}` (e.g., `v0.2.0`).

To create a new release:

1. Go to **Releases** > **Draft a new release** in the GitHub UI.
2. Create a new tag matching `v${version}`.
3. Set the release title to the version (e.g., `v0.2.0`).
4. Generate or write release notes describing the changes.
5. Click **Publish release**.

Publishing a release automatically:

- Deploys the generated documentation to GitHub Pages at
  https://dash0hq.github.io/dash0-semantic-conventions/.
- Opens a pull request in `dash0hq/dash0-website` to sync the semantic
  conventions pages to [docs.dash0.com](https://docs.dash0.com) under
  **OpenTelemetry → Dash0 Semantic Conventions**.
  Review and merge that PR to make the updated docs live on the website.

> **Before the first syncing release**, ensure the following repository
> secrets are set in `dash0hq/dash0-semantic-conventions` settings:
> `DASH0_DOCS_REPO_GITHUB_PAT`, `SYNC_DOCUMENTATION_TARGET_REPOSITORY`,
> `SYNC_DOCUMENTATION_TARGET_DIRECTORY`.