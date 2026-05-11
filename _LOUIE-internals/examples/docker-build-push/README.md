Source material for the planned `docker:build-push` recipe — captured from a real project (Weinchen: Node monorepo with React client + Express server + shared TS lib + Drizzle migrations).

## Purpose

These three files ground the recipe's Implementation Guidance in concrete shapes rather than abstract handwaving. They are **reference only** — they are not distributed (lives under `_LOUIE-internals/`), they are not referenced from the recipe itself, and they should not be edited as part of normal framework work.

When the `docker:build-push` recipe is written, its Implementation Guidance section abstracts these patterns; it does **not** quote them verbatim. The recipe must remain stack-agnostic (Node, Python, Go, Rust, etc.) — these files happen to be Node because that's the source project.

## Files

| File | Runs on | Purpose |
|------|---------|---------|
| `buildpush.sh` | Dev machine | Build the image locally, tag it, push to the registry. Supports `--no-push` for build smoke-tests. |
| `Dockerfile` | (Build-time) | Multi-stage build — shared lib → client → server → minimal production image. Demonstrates the build-then-copy pattern with cache-friendly dependency layers. |
| `update.sh` | Production server | Stop the running container, remove the old image, pull `:latest` from the registry, restart the container. |

## Redactions

To avoid committing real secrets / private hostnames to git history, the following values were replaced with marker placeholders:

| Original (in source) | Replaced with | Where |
|---|---|---|
| Real registry hostname | `registry.example.internal` | `buildpush.sh`, `update.sh` |
| Real database hostname | `db.example.internal` | `update.sh` |
| Real database password | `REDACTED_DO_NOT_USE_THIS_PATTERN` | `update.sh` |

The placeholder for the password is deliberately verbose — the `update.sh` original embedded the real password directly in `docker run -e DATABASE_PASSWORD=...`, which is the exact anti-pattern the recipe's Pitfalls section calls out (exposed via `ps aux`, shell history, container metadata). The recipe enforces `--env-file /path/to/.env.production` instead. The redacted file is left as-is structurally so the next session can see the bad pattern and abstract it correctly.

## Known issues in the source (the recipe should fix these)

1. **`buildpush.sh` computes `BUILD_VERSION` from the latest git tag but never uses it** — the image is always pushed as `:latest`. The recipe should derive a real tag (`:vX.Y.Z` on tagged HEADs, `:vX.Y.Z-sha<short>` for dev builds off a tagged base, `:sha-<short>` when no tag exists in history) and push both the derived tag and `:latest`.
2. **`update.sh` bakes env vars (including the DB password) into the `docker run` command** — replace with `--env-file` reading from a gitignored `.env.production`.
3. **Single-arch `docker build`** (no `buildx`, no `--platform`) — fine as a default, since most single-VM deploys are one arch. Multi-arch becomes a Variation in the recipe.

These are intentional in the source (it's a working production setup), not bugs to file. They become design choices in the recipe.
