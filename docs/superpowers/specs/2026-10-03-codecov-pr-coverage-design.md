# Codecov Pull Request Coverage Design

## Goal

Show merged project and patch coverage on every pull request through a Codecov
comment and informational status checks, without changing merge eligibility.

## Current State

`.github/workflows/tests.yml` already runs sharded Flutter tests with coverage,
merges the generated LCOV reports, removes generated-code paths, uploads the
final `coverage.info` artifact, and uploads that same report through
`codecov/codecov-action@v5`. The repository is private and supplies
`CODECOV_TOKEN` to the upload step.

## Design

Update the existing repository-root `codecov.yml`. It configures the existing
Codecov upload; no GitHub Actions job, token, or test command changes are
needed. Preserve its generated-code and localization ignore rules.

### Pull Request Comment

Configure Codecov to post a comment whenever it has a head coverage report.
The comment will include project coverage, patch/diff coverage, flags, and
changed files. It will not require a base report and it will not be limited to
PRs that change coverage, so authors can see the current project total on every
PR.

### Informational Checks

Enable both Codecov project and patch status checks. Each uses `target: auto`,
which compares against Codecov's selected base, with a `0%` threshold. Both
checks are explicitly informational, so they communicate coverage changes but
cannot block a pull request or merge.

## Configuration

```yaml
comment:
  layout: "diff, flags, files"
  behavior: default
  require_changes: false
  require_base: false
  require_head: true
  hide_project_coverage: false

coverage:
  status:
    project:
      default:
        target: auto
        threshold: 0%
        informational: true
    patch:
      default:
        target: auto
        threshold: 0%
        informational: true

ignore:
  - "**/*.g.dart"
  - "**/*.freezed.dart"
  - "lib/l10n/**"
```

## Acceptance Criteria

- Codecov receives the existing merged LCOV upload unchanged.
- Each PR with a head report receives a Codecov comment showing project and
  patch coverage.
- Codecov emits project and patch coverage checks for PRs.
- Both checks are informational and do not block merging.
- The configuration validates with Codecov's YAML validation endpoint.
