# Contributing

This document covers the full development workflow: branch naming, the feature → dev → main flow, what is automated by CI, and step-by-step instructions for each stage.

---

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Production. Every merge here deploys to users and may trigger a release. |
| `dev` | Integration. All feature and fix branches target this. |
| `feat/<issue#>-<description>` | A new feature tied to a GitHub issue. |
| `fix/<issue#>-<description>` | A bug fix tied to a GitHub issue. |
| `chore/<issue#>-<description>` | Maintenance work (deps, config, refactors, docs). |

**Examples**

```
feat/42-custom-recurrence
fix/17-day-picker-not-showing
chore/8-update-dependencies
```

Rules:
- Always branch off `dev`, never off `main`.
- Use lowercase and hyphens only — no spaces, no uppercase.
- Include the issue number so the branch is traceable.

---

## Flow overview

```
feat/42-...  ─┐
fix/17-...   ─┤──► dev ──────────────────────► main ──► GitHub Pages /aadat/ (live to users)
chore/8-...  ─┘     │                            │
                     │                            └──► GitHub Release (created automatically)
                     └──► GitHub Pages /aadat/dev/ (preview build)
```

Feature and fix branches feed into `dev`. Every push to `dev` automatically deploys a preview build so you can test changes before they reach users. When enough changes have accumulated, `dev` is merged into `main` as a release, which deploys to the live URL.

---

## Day-to-day: working on a feature or fix

### 1. Create a GitHub issue

Before starting any work, open an issue describing what you are building or fixing. Note the issue number — you will use it in your branch name.

### 2. Create a branch from `dev`

```bash
git checkout dev
git pull origin dev
git checkout -b feat/42-custom-recurrence
```

### 3. Write and commit your changes

Follow the **Conventional Commits** format. This is important — the release script uses these commit messages to auto-suggest changelog entries.

| Prefix | When to use |
|--------|-------------|
| `feat:` | A new feature visible to users |
| `fix:` | A bug fix |
| `chore:` | Dependency updates, config changes, refactors, docs |

```bash
git commit -m "feat: add custom recurrence day picker"
git commit -m "fix: hide day picker when recurrence is not custom"
```

One logical change per commit. Avoid commits like "wip" or "misc changes".

### 4. Open a pull request into `dev`

Title your PR the same way you would a commit:

```
feat: add custom recurrence day picker (#42)
```

In the PR body, add a closing keyword so the issue closes automatically on merge:

```
Closes #42
```

### 5. Merge into `dev`

Review the diff, then merge. Squash if the branch has noisy intermediate commits; merge commit if each commit is meaningful on its own.

Merging triggers `deploy-dev.yml`, which builds and deploys the updated `dev` branch to the preview URL. Use this to test your changes before they ship.

### 6. Test on the dev build

Open the live app, go to **Settings → Developer → Open dev build**. This navigates to the `/aadat/dev/` preview URL where your merged changes are live.

If you want others to preview a change before it merges, share the dev URL directly: `https://<username>.github.io/aadat/dev/`

### 7. Track unreleased changes in `kDevChangelog`

As you merge features and fixes into `dev`, add a plain-English entry to `kDevChangelog` in `lib/data/changelog.dart`:

```dart
const List<ChangeEntry> kDevChangelog = [
  ChangeEntry(ChangeType.feature, 'Custom recurrence — pick specific days of the week'),
  ChangeEntry(ChangeType.fix, 'Day picker now hides when recurrence is not Custom'),
];
```

This list has no user-facing effect — it is only visible in the Developer section of Settings. When you release, move these entries into `kChangelog` under the new version key and clear `kDevChangelog`.

---

## Releasing: merging `dev` into `main`

Do this when you have accumulated enough changes on `dev` that you want to ship them to users.

### 1. Decide the new version number

Use [Semantic Versioning](https://semver.org): `MAJOR.MINOR.PATCH`

| Change | Bump |
|--------|------|
| Breaking change or major redesign | MAJOR (`1.0.0 → 2.0.0`) |
| New feature | MINOR (`0.1.0 → 0.2.0`) |
| Bug fix only | PATCH (`0.1.0 → 0.1.1`) |

When in doubt, a release that contains any new features is a MINOR bump.

### 2. Run the release preparation script

From the root of the repo:

```bash
./scripts/prepare_release.sh 0.2.0
```

This script:
- Updates the version in `pubspec.yaml`
- Updates `kAppVersion` in `lib/data/changelog.dart`
- Prints suggested `kChangelog` entries generated from your conventional commits since the last release

### 3. Update the in-app changelog

Open `lib/data/changelog.dart`. The script output will look like:

```dart
  '0.2.0': [
    ChangeEntry(ChangeType.feature, 'add custom recurrence day picker'),
    ChangeEntry(ChangeType.fix, 'hide day picker when recurrence is not custom'),
  ],
```

Paste this block into `kChangelog` and **rewrite the descriptions in plain English for users** — not developer commit messages. For example:

```dart
  '0.2.0': [
    ChangeEntry(ChangeType.feature, 'Custom recurrence — pick specific days of the week for a habit'),
    ChangeEntry(ChangeType.fix, 'Day picker now stays hidden unless Custom recurrence is selected'),
  ],
```

### 4. Commit and push

```bash
git add pubspec.yaml lib/data/changelog.dart
git commit -m "chore: release v0.2.0"
git push origin dev
```

### 5. Open a pull request: `dev` → `main`

Title:

```
release: v0.2.0
```

No issue number needed for release PRs. CI will automatically validate:

- `kAppVersion` in `changelog.dart` matches `pubspec.yaml`
- `kChangelog` has an entry for the new version
- The version was actually bumped relative to `main`

If any check fails, fix the issue and push to the branch — CI reruns automatically.

### 6. Merge into `main`

Once CI passes, merge the PR. This triggers two automated actions:

1. **Deploy** — `deploy.yml` builds Flutter Web and publishes to GitHub Pages. Users get the new version within a few minutes.
2. **Release** — `release.yml` detects the version bump and creates a GitHub Release with an auto-generated summary of merged PRs.

The What's New popup will appear the next time each user opens the app — it compares the shipped `kAppVersion` against the version stored in their browser's local storage.

---

## CI at a glance

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `deploy-dev.yml` | Push to `dev` | Builds Flutter Web and deploys to `/aadat/dev/` (preview) |
| `validate-release-pr.yml` | PR to `main` | Blocks merge if version not bumped, `kAppVersion` mismatches `pubspec.yaml`, or `kChangelog` entry is missing |
| `deploy.yml` | Push to `main` | Builds Flutter Web and deploys to `/aadat/` (live), preserving the `/dev/` subfolder |
| `release.yml` | Push to `main` | Creates a GitHub Release + tag if the version changed |

### One-time GitHub Pages setup

The deploy workflows write to a `gh-pages` branch rather than using GitHub's built-in Actions deployment. This is what enables deploying to separate subfolders for `main` and `dev`.

After the first deploy runs and creates the `gh-pages` branch, update the GitHub Pages source:

1. Go to **Settings → Pages → Build and deployment → Source**
2. Switch from `GitHub Actions` to `Deploy from a branch`
3. Set branch to `gh-pages`, folder to `/ (root)`

---

## Quick reference

```bash
# Start a feature
git checkout dev && git pull origin dev
git checkout -b feat/42-description

# Commit
git commit -m "feat: description of change"

# Prepare a release (run on dev branch)
./scripts/prepare_release.sh 0.2.0
# → edit lib/data/changelog.dart with user-facing descriptions
git add pubspec.yaml lib/data/changelog.dart
git commit -m "chore: release v0.2.0"
```
