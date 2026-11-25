# Publishing Jetleaf packages

Jetleaf is a Dart workspace: a root package (`jetleaf`) plus independently
published packages under `libraries/` and `packages/`. Each package has its own
version, tag, and pub.dev page.

## Package requirements

Every publishable directory must contain:

- `pubspec.yaml` with `name` and `version`
- `LICENSE`
- `README.md`
- `CHANGELOG.md`

The version in `pubspec.yaml` must match the version encoded in the release tag.

## The workspace `.pubignore` trap

`dart pub publish` reads `.pubignore` from the **workspace root**, even when it
is run from inside a child package. The root `.pubignore` contains:

```
libraries/
packages/
```

Those rules keep child packages out of the root `jetleaf` archive, but they
also exclude every file of a child package. The result is an empty archive and
misleading validation errors:

- `The pubspec is hidden, probably by .gitignore or pubignore`
- `You must have a LICENSE file in the root directory`
- missing `README.md` / `CHANGELOG.md` warnings

Do not remove those rules permanently. Both publishing paths below strip them
only for the duration of a child-package publish and restore them afterwards.

## Local publishing

Run `scripts/publish-package.sh` from the repository root:

```bash
scripts/publish-package.sh libraries/jetleaf_core --dry-run   # validate only
scripts/publish-package.sh libraries/jetleaf_core --force     # publish
scripts/publish-package.sh packages/jetleaf_data --force
scripts/publish-package.sh packages/jetleaf_security --force
scripts/publish-package.sh . --force                          # root package
```

The script:

1. backs up `.pubignore`;
2. removes the `libraries/` and `packages/` rules (skipped for the root package,
   which still needs them);
3. runs `dart pub publish` in the target directory, forwarding any extra
   arguments (`--dry-run`, `--force`, etc.);
4. restores `.pubignore` via a trap, even if publishing fails.

Local publishing authenticates with your own pub.dev account and is not subject
to the tag restriction described below. It is **required for the first version
of a new package** — pub.dev only allows automated publishing for packages that
already exist on pub.dev. After the initial release, CI can publish updates.

## Automated publishing from GitHub Actions

`release-on-merge.yml` runs when a PR is merged into `main`, or via
`workflow_dispatch`. It creates an annotated tag and a GitHub Release for each
package whose version is not tagged yet:

| Package | Tag format | Example |
| :--- | :--- | :--- |
| root `jetleaf` | `v<version>` | `v2.1.0` |
| child package | `<name>-v<version>` | `jtl-v2.1.0` |

It must push tags with a token that can trigger other workflows. The default
`GITHUB_TOKEN` cannot: GitHub suppresses workflows triggered by it. Set the
`RELEASE_TOKEN` repository secret to a fine-grained PAT with **Contents: write**
on `jetleaf/jetleaf`, a classic PAT with `repo` scope, or a GitHub App token.

Each tag push triggers `publish.yml`, which:

- publishes only when `github.ref_type == 'tag'`; branch pushes and manual
  dispatches run `dart pub publish --dry-run` validation only, because pub.dev's
  OIDC check rejects tokens with a `branch` refType;
- skips any package whose own `<name>-v<version>` tag is not the triggering tag,
  so every package is published by its own run;
- skips versions already present on pub.dev;
- temporarily strips the two `.pubignore` rules for child packages;
- queues runs with `concurrency: publish-pub-dev` so publishes do not race.

On pub.dev, enable **Admin → Automated publishing** for each package with
repository `jetleaf/jetleaf` and a matching tag pattern:

- root: `v{{version}}`
- `jtl`: `jtl-v{{version}}`
- `jetleaf_core`: `jetleaf_core-v{{version}}`
- …and so on for every package

Each package needs its own pattern. A missing or mismatched pattern, or the
wrong repository, is rejected by pub.dev.

## Triggering publish for tags that already exist

`release-on-merge.yml` skips tags that are already on the remote, so re-running
it will not start any publish runs. To publish existing tags, delete and
re-push a tag to generate a real push event:

```bash
git fetch --tags origin
git push origin --delete jtl-v2.1.0
git push origin jtl-v2.1.0
```

Watch the Actions tab for the `Publish to pub.dev` run on that tag. Once it
succeeds, repeat for the remaining tags.

## Troubleshooting

| Symptom | Cause and fix |
| :--- | :--- |
| Archive `<1 KB`, "pubspec is hidden", missing LICENSE/README/CHANGELOG | A child package was published without the `.pubignore` workaround. Use `scripts/publish-package.sh` or the CI workflow. |
| `publishing is only allowed from 'tag' refType` | The workflow ran from a branch push or manual dispatch. Publishing requires a tag push. |
| No `publish` run after `release-on-merge` | Tags were pushed with `GITHUB_TOKEN`. Set `RELEASE_TOKEN` and re-push the tags. |
| `Insufficient permissions to the resource at pub.dev` | Automated publishing is not enabled for that package, or its tag pattern / repository does not match the tag. |
| Summary rows saying `Skipped (tag mismatch)` | Expected: only the package whose tag triggered the run is published. |
| Many publish runs queued | Expected: one tag per package, serialized by the concurrency group. |