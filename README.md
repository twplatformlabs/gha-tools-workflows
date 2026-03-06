<div align="center">
	<p>
		<img alt="Thoughtworks Logo" src="https://raw.githubusercontent.com/twplatformlabs/static/master/psk_banner.png" width=800 />
	</p>
  <h2>gha-tools-workflows</h2>
  <h4>for GitHub Actions pipelines</h4>
  <img alt="GitHub Actions Workflow Status" src="https://img.shields.io/github/actions/workflow/status/twplatformlabs/gha-tools-workflows/.github%2Fworkflows%2Fdevelopment-build.yaml"> <img alt="GitHub Release" src="https://img.shields.io/github/v/release/twplatformlabs/gha-tools-workflows"> <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</div>
<br />

Shared workflows for building and maintaining GitHub Actions, Workflows, and Runners.  

## Workflows

Used for the SDLC management of shared GitHub Actions and Workflows. Workflows also demonstrate integrated support for secrets management using 1password which can be adapted to most centralized solutions.  

### action-dev-build.yaml

A continuous-integration workflow for GitHub Actions triggered on every commit pushed.  

Uses the following tools to provide feedback and quality controls:  
- ibiqlik/action-yamllint
- ludeeus/action-shellcheck (based on koalaman/shellcheck)
- github/codeql-action
- ossf/scorecard-action _confirmation_

Example usage:  
github.com/twplatformlabs/common-actions/.github/workflows/dev-build.yaml
```yaml
name: common-actions development build

on:
  push:
    branches:
      - "*"
    tags:
      - "!*"

permissions:
  contents: read
  actions: read
  security-events: write

jobs:

  static-code-analysis:
    name: static code analysis
    uses: twplatformlabs/gha-tools-workflows/.github/workflows/action-dev-build.yaml@v1

  integration-tests:
    name: integration test
    needs: static-code-analysis
    uses: ./.github/workflows/integration-tests.yaml
    secrets:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
```

This is an example of a complete workflow in an Action repository. The static-code-analysis job uses the shared action-dev-build workflow to analyze the Action code and when the results are passing will call a local integration-test workflow to verify the functional correctness.  

The ossf-scorecard check currently just confirms that a local workflow with the default name exists. The ossf-scorecard.yaml workflow in this repository is a ready-to-use example that can be copy/pasted into any Action repository.  

### action-release.yaml

Typically, Actions are released by tagging the desired commit with a semantic release version. This workflow triggers on that event and generates a GitHub release with notes and optionally sends a text to a Slack channel.  

Example usage:  
github.com/twplatformlabs/common-actions/.github/workflows/release.yaml
```yaml
name: common-actions release

on:
  push:
    branches:
      - "!*"
    tags:
      - "v[0-9]*.[0-9]*.[0-9]*"
      - "v[0-9]*.[0-9]*.[0-9]*-rc"

permissions:
  contents: write
  issues: write

jobs:

  release-version:
    name: release version
    uses: twplatformlabs/gha-tools-workflows/.github/workflows/action-release.yaml@v1
    secrets:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
    with:
      before-release: "true"
      release-generate-notes: "true"
      release-chat-annoucement: "New release of twplatformlabs/common-actions"
```

### runner-dev-build.yaml and runner-release.yaml

A continuous-integration workflow for custom GitHub Action Runners triggered on every commit pushed.  

Uses the following tools to provide feedback and quality controls:  
- hadolint/hadolint-action
- twplatformlabs/gha-tools-actions/buildx (performs bake file build, enabling basic bill of materials and provenance generation)
- (Optional) twplatformlabs/gha-tools-actions/bats (run custom Bats tests against running instances of each bake file target build)
- (Optional) twplatformlabs/gha-tools-actions/scout-scan (Perform Docker Scout CVE scan on bake file targets)

Example usage: Combines both workflows in a single definition. Could be separately triggered definitions.  

github.com/twplatformlabs/runner-base-image/.github/workflows/development-build-and-release.yaml
```yaml
name: runner-base-image development build and release

on:
  push:
    branches:   # triggers on either push or tag
      - "*"
    tags:
      - "*"

permissions:
  contents: write
  actions: read
  security-events: write

jobs:

  runner-dev-build:
    name: runner-base-image development build
    uses: twplatformlabs/gha-tools-workflows/.github/workflows/runner-dev-build.yaml@main
    with:
      before-build: "true"
      registry: ghcr.io
      skip-hadolint: "false"
      bats-test: "true"
      bats-test-path: "test/runner-base-image.bats"
    secrets:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}

  release:
    name: runner-base-image release
    if: startsWith(github.ref, 'refs/tags/')   # only runs if triggered by tag and dev build succeeds
    uses: twplatformlabs/gha-tools-workflows/.github/workflows/runner-release.yaml@main
    needs: runner-dev-build
    with:
      before-release: "true"
      registry: ghcr.io
      include-latest: "true"
      sign-manifest: "true"
    secrets:
      OP_SERVICE_ACCOUNT_TOKEN: ${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}
```

### ossf-scorecard.yaml

As described above, this workflow is currently used by simply copy/pasting the the yaml file into your custom Action repository.  

The workflow runs on commits and as a 30-day cron trigger.  

Like the codeql scan, the results of the ossf analysis are published to the repository `Security` tab in the `Code scanning` section. Review the [ossf-scorecard documentation](https://github.com/ossf/scorecard) for detailed usage information.  
