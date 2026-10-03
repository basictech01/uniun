# Codecov Pull Request Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add non-blocking Codecov pull-request comments and project/patch coverage checks using the repository's existing merged LCOV upload.

**Architecture:** A root `codecov.yml` configures Codecov after the existing `coverage.info` upload in `.github/workflows/tests.yml`. It does not add a workflow or mutate the upload action: Codecov consumes the current report, comments on each PR with project and patch coverage, and publishes informational statuses only.

**Tech Stack:** GitHub Actions, `codecov/codecov-action@v5`, Codecov YAML configuration, LCOV.

## Global Constraints

- Keep `.github/workflows/tests.yml` unchanged; it already merges shard coverage and uploads `coverage.info` to Codecov with `CODECOV_TOKEN`.
- Update the existing repository-root `codecov.yml`; preserve its generated-code and localization ignore rules.
- Do not add a second uploader, a token, or a dependency.
- PR comments must show project coverage as well as patch coverage.
- Project and patch Codecov checks must be informational and must not block merging.
- Validate the final YAML with Codecov's validation endpoint before opening the PR.

---

## File Structure

- Modify: `codecov.yml` — extend the existing repository-wide Codecov comment and informational-status configuration.
- Retain: `docs/superpowers/plans/2026-10-03-codecov-pr-coverage.md` — this execution plan.
- Retain: `docs/superpowers/specs/2026-10-03-codecov-pr-coverage-design.md` — approved design and acceptance criteria.
- Do not modify: `.github/workflows/tests.yml` — existing coverage upload integration.

### Task 1: Update Codecov PR reporting configuration

**Files:**

- Modify: `codecov.yml`
- Reference: `.github/workflows/tests.yml:212-275`
- Reference: `docs/superpowers/specs/2026-10-03-codecov-pr-coverage-design.md`

**Interfaces:**

- Consumes: the existing Codecov upload of `coverage.info` from the `coverage` GitHub Actions job.
- Produces: Codecov PR comment plus `codecov/project` and `codecov/patch` informational statuses.

- [ ] **Step 1: Confirm the existing upload contract**

Run:

```bash
sed -n '212,275p' .github/workflows/tests.yml
```

Expected: the `coverage` job merges LCOV shard artifacts and invokes `codecov/codecov-action@v5` with `files: coverage.info` and `CODECOV_TOKEN`.

- [ ] **Step 2: Create the configuration**

Update `codecov.yml` to contain:

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

- [ ] **Step 3: Validate YAML syntax locally**

Run:

```bash
python3 -c 'import yaml; print(yaml.safe_load(open("codecov.yml", encoding="utf-8")))'
```

Expected: parsed YAML with `comment`, `coverage`, and the existing `ignore` paths.

- [ ] **Step 4: Validate against Codecov**

Run:

```bash
curl --fail --silent --show-error --data-binary @codecov.yml https://codecov.io/validate
```

Expected: a successful response from Codecov's configuration validator.

- [ ] **Step 5: Inspect the resulting diff**

Run:

```bash
git diff --check
git diff -- codecov.yml
```

Expected: no whitespace errors; only the new Codecov configuration is shown.

- [ ] **Step 6: Commit the implementation**

Run:

```bash
git add codecov.yml docs/superpowers/specs/2026-10-03-codecov-pr-coverage-design.md docs/superpowers/plans/2026-10-03-codecov-pr-coverage.md
git commit -m "ci: add Codecov PR coverage reporting"
```

Expected: one commit containing the Codecov configuration and implementation plan.

### Task 2: Publish and verify the pull request

**Files:**

- Modify: none

**Interfaces:**

- Consumes: committed `codecov.yml` and the existing GitHub Actions coverage upload.
- Produces: a pull request whose CI run uploads coverage and whose Codecov integration posts an informational result.

- [ ] **Step 1: Push the branch**

Run:

```bash
git push -u origin chore/codecov-pr-coverage
```

Expected: remote branch is created and tracks `origin/chore/codecov-pr-coverage`.

- [ ] **Step 2: Open the pull request**

Run:

```bash
gh pr create --base main --head chore/codecov-pr-coverage --title "ci: add Codecov PR coverage reporting"
```

Expected: GitHub prints the new PR URL. Its body must state that the change reuses the existing merged LCOV upload and that all Codecov checks are informational.

- [ ] **Step 3: Check CI completion**

Run:

```bash
gh pr checks <pr-number> --watch
```

Expected: the existing coverage job passes and Codecov receives the merged LCOV upload.

- [ ] **Step 4: Confirm Codecov delivery**

Inspect the PR conversation and checks after CI completes.

Expected: a Codecov comment displays project and patch coverage; project and patch statuses are present and informational, so neither can block merge.

## Plan Self-Review

- Spec coverage: Task 1 implements every approved comment and informational-status setting; Task 2 verifies the hosted integration on a real PR.
- No placeholders: all paths, YAML values, commands, expected results, branch name, and PR metadata are explicit.
- Consistency: `codecov.yml` is the sole configuration artifact and consumes the unchanged `coverage.info` upload described in the design specification.
