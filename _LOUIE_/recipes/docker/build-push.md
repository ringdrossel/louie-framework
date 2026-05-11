Build a single image, push it to one registry, and deploy it to a server — a simple containerisation flow producing a Dockerfile, a dev-side build/push script, and a server-side update script.

# Docker Build, Push, and Deploy

## Overview

This is a **simple containerisation recipe**. It produces three artifacts:

- A **Dockerfile** at (or near) the project root that builds the application image.
- A **`buildpush.sh`** dev-side script that resolves a tag from git, builds the image, and pushes it to the project's registry.
- An **`update.sh`** server-side script that pulls the latest image and cycles the running container.

The recipe targets the common case: one application image, one Dockerfile, one registry, one (or a small number of) long-lived server(s). It deliberately stays small so projects can adopt it without committing to an orchestrator or a CI pipeline.

### Use this when

- The project ships as a single application image (web app, API server, worker, CLI daemon).
- Deployment is to a long-lived server (VM, bare-metal host) that runs `docker` directly.
- A dev or release engineer runs the build + deploy by hand or via a thin wrapper.
- The team wants a working Docker workflow today and can layer CI / multi-arch / orchestration on later.

### Do not use this for

- Multi-image stacks (app + worker + scheduler each as its own image) — invoke the recipe once per image, or wait for a future `docker:multi-image` recipe.
- Local-dev orchestration with hot reload — that's `dev:docker-compose` (planned).
- CI-driven build and push — pieces are reusable, but a full CI recipe is its own concern.
- Kubernetes / ECS / Cloud Run / Nomad — different deploy models entirely.

### Prerequisites

- A confirmed `_LOUIE-output/architecture.md` and `_LOUIE-output/tech-stack.md` (the architecture gate).
- A reachable image registry the team controls (Docker Hub, GHCR, ECR, GAR, or a generic self-hosted registry).
- A deploy target that has `docker` installed and can pull from the chosen registry.
- A way to provision a `.env.production` file on the server out-of-band (Vault, SSH copy, config-management — recipe doesn't prescribe).

## Requirements Seed

### Functional

1. The project builds a single Docker image via a Dockerfile checked into the repository.
2. A `buildpush.sh` script on the developer's machine builds the image and pushes it to the configured registry.
3. The script computes the image tag from git:
   - When `HEAD` is at a version tag → push `:vX.Y.Z`.
   - When `HEAD` is a descendant of a version tag → push `:vX.Y.Z-sha<short>`.
   - When the repository has no version tag in history → push `:sha-<short>`.
   - In every case, also push `:latest` alongside.
4. The script supports `--no-push` for a build-only smoke test.
5. The image embeds its resolved tag somewhere readable from inside the container (an OCI label, an env var, or a `/etc/build-info` file — the project picks one).
6. An `update.sh` script on the production server pulls the new image, stops and removes the running container, and starts a fresh one.
7. The container runs with `--restart unless-stopped` so a host reboot does not drop the service.
8. The container's runtime configuration comes from `--env-file /path/to/.env.production`. Inline `-e` flags for secrets are forbidden; non-secret env vars may stay inline if the project prefers, but consistency through `--env-file` is recommended.
9. The deployed container exposes the application on a host port mapped to the container's listening port.
10. The `docker login` flow for the chosen registry is documented in `_LOUIE-output/runbook.md`. The recipe's scripts do **not** call `docker login` and do **not** read credentials.

### Non-Functional

- The Dockerfile produces a slim production image: dev dependencies and build tooling are dropped from the final stage; the image runs as a non-root user.
- Build is single-arch (matches typical single-VM deploys). Multi-arch is a Variation, not the default.
- `buildpush.sh` and `update.sh` both set `set -euo pipefail` and fail loudly on any error.
- Image name lives in one place per script — a single config variable at the top of each file — to keep `buildpush.sh` and `update.sh` agreeing on the same path.
- A `.dockerignore` excludes VCS metadata, local dev outputs, env files, and IDE folders so they never enter the build context.

### Out of Scope

- Multi-image / multi-Dockerfile builds in a single recipe invocation.
- Multi-arch builds (Variation).
- Compose-based local dev (separate recipe, see *Variations*).
- CI / GitHub Actions / GitLab CI integration (Variation).
- Kubernetes / ECS / Cloud Run / Nomad deployment (different deploy models entirely).
- Blue/green or zero-downtime deploys — brief downtime during the stop/rm/run cycle is accepted (Variation for blue/green).
- Image scanning, SBOM generation, signing (Variations).
- Auth setup beyond documenting the `docker login` command for the chosen registry.
- Credential storage. The recipe never writes credentials into a LOUIE artifact.

## Architecture Notes

### Where the registry choice lives

Container registry identity is **build/deploy-time** configuration — it is not a runtime component of the system. It belongs in `_LOUIE-output/tech-stack.md`, not in `_LOUIE-output/architecture.md`.

Sophie should add (or update) a **Container Registry** subsection under the existing **Infrastructure** section of `tech-stack.md` capturing:

- Registry type (Docker Hub / GHCR / ECR / GAR / generic self-hosted).
- Registry host and image path prefix (e.g. `ghcr.io/<org>/<image>`, `<account>.dkr.ecr.<region>.amazonaws.com/<image>`).
- Tag strategy (per this recipe — `:vX.Y.Z` / `:vX.Y.Z-sha<short>` / `:sha-<short>`, with `:latest` always pushed).
- Base image policy (pinned version vs. floating major, e.g. `node:20.11-alpine` vs. `node:20-alpine`).

Operational details — the actual `docker login` command for the chosen registry, the build/push/deploy commands the team types, the env-var contract the deployed container expects, the container user, the port mapping, the restart policy, and accumulating gotchas — go in `_LOUIE-output/runbook.md`:

- **Deployment Model:** call out that the app ships as a Docker image and is deployed by `docker run` with `--restart unless-stopped`.
- **Ports & Endpoints:** the host port → container port mapping.
- **Common Commands:** the `docker login`, `./buildpush.sh`, `./update.sh`, and tail-the-logs commands.
- **Environment & Dependencies:** the `.env.production` contract (variable names, what each is for) — values stay on the server, not in the doc.
- **Common Gotchas:** seed with two — "registry token expired (401 on push)" and "container stopped without `--restart unless-stopped` won't survive a reboot."

### Things Sophie should validate

- The project actually wants a Dockerfile at all. Some stacks (serverless, JVM with native packaging, static-site hosts) have natural alternatives. If the project's deploy model doesn't fit single-image / single-server, push back.
- The chosen registry is reachable from both the dev machine and the production server.
- The project's existing port assignments don't collide with the proposed host port mapping.
- If the project already has a Dockerfile, decide whether to extend it or replace it before Nina starts writing.
- If the project ships multiple processes (web + worker + scheduler), confirm with the user whether a single image with a process switch is acceptable or whether the recipe should be invoked separately per process.

### Architecture gate

If Sophie amends `tech-stack.md` to add the Container Registry subsection (or to adjust an existing one), the architecture confirmation gate fires per the standard recipe flow. No new gate type; this is the existing gate doing its job.

## Implementation Guidance

### Dockerfile patterns

This recipe ships **three reference patterns**. Nina picks the one that matches the project's shape; Sophie validates the choice during her eval.

#### Pattern A — single-package application

A single language/runtime with one buildable package (single Node app, single Python service, single Go binary, single Rust binary).

Two stages:

1. **Builder** — base image with the language toolchain. Install dependencies (cache-friendly: copy manifest, install, then copy source). Build/compile.
2. **Runtime** — minimal base image (alpine, distroless, or `scratch` for static binaries). Copy only the built artifact and runtime dependencies from the builder stage. Set `ENV` defaults, `EXPOSE` the listen port, declare a non-root `USER`, set the `CMD` / `ENTRYPOINT`.

Aim for the smallest plausible runtime base. For Node and Python, install production-only dependencies (`npm ci --omit=dev`, `pip install --no-dev` equivalent) in the runtime stage. For Go and Rust, the runtime stage typically contains just the binary and its non-binary assets.

#### Pattern B — monorepo with shared library

Multiple packages in one repository where a shared library is consumed by one or more application packages (e.g. shared TS lib + React client + Node server).

Stage chain — one builder per package, then a slim production stage:

1. **`shared-build`** — install shared package dependencies, copy shared source, build. Independent stage so its output layer caches across client and server builds.
2. **`client-build`** — install client + shared deps, copy `shared/dist` from stage 1, copy client source, build.
3. **`server-build`** — install server + shared deps, copy `shared/dist` from stage 1, copy server source, build.
4. **`production`** — minimal base, install **production-only** dependencies for shared + server (`npm ci --omit=dev` or the language equivalent), copy compiled output from the builder stages, copy migrations / static assets needed at runtime, set `ENV` defaults, `EXPOSE`, declare a non-root `USER`, set the `CMD`.

The production stage re-runs the install step with `--omit=dev` (or equivalent) deliberately — this drops dev tooling that survived in the builder stages. The build time cost is real but small; the image-size and attack-surface payoff is large.

Copy `package*.json` (or equivalent manifest) before copying source so Docker's layer cache reuses the install step when only source changes.

#### Pattern C — generic non-Node (compiled binary)

Compiled languages where the output is a single binary or a small set of files (Go, Rust, Java fat-jar, .NET self-contained).

Two stages:

1. **Builder** — full language toolchain. Build the artifact.
2. **Runtime** — the smallest base that runs the artifact: `scratch` for static binaries, `gcr.io/distroless/...` for hardened minimal, `alpine` when libc / shell access is needed. Copy only the binary (and any non-binary assets — config templates, static files). Set `ENV`, `EXPOSE`, non-root `USER`, `CMD` / `ENTRYPOINT`.

Static linking pays double here — a statically-linked binary lets the runtime stage be `FROM scratch`, which is the smallest and most hardened option Docker offers.

### Cross-pattern guidance (applies to all three)

- **`.dockerignore` is required.** Floor: `.git`, `node_modules` (or language equivalent), `dist`/`build` outputs, `.env*`, IDE folders (`.vscode/`, `.idea/`), local logs. Add per-pattern entries (e.g. `coverage/`, `__pycache__/`) as needed. Excluding `.env*` from the build context prevents secrets from leaking into image layers.
- **Non-root `USER` in the image, not at deploy time.** Declare the user (and create it if the base image doesn't ship one) inside the Dockerfile. `docker run --user` overrides are fine for one-offs, but baking the user into the image keeps the contract portable and the deploy script simpler.
- **Pin the base image to a specific minor version** (`node:20.11-alpine`, not `node:latest` and not `node:20`). Floating tags drift; reproducibility matters when something breaks two months from now.
- **Embed the resolved tag in the image.** Pick one: an OCI label (`LABEL org.opencontainers.image.version="<tag>"`), an env var (`ENV BUILD_VERSION=<tag>`), or a `/etc/build-info` file. The build script knows the tag; pass it in as a build arg and apply it. Operators read it later with `docker inspect` or by exec-ing into the container.
- **Healthcheck (optional).** If the application exposes a health endpoint, add a `HEALTHCHECK` stanza. Compose and orchestrators react to it.
- **Build context root.** For monorepos, the build context is typically the repo root so the Dockerfile can reach every package's source. Place the Dockerfile wherever the project structure prefers; the `buildpush.sh` script passes the right context explicitly.

### `buildpush.sh` — dev-side build and push

Run on the developer's machine. Single-arch `docker build` and `docker push`.

Structure:

```
#!/bin/bash
set -euo pipefail

IMAGE_NAME="<registry-host>/<namespace>/<image>"     # single source of truth
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="${SCRIPT_DIR}/Dockerfile"
CONTEXT="${SCRIPT_DIR}"

NO_PUSH=false
[[ "${1:-}" == "--no-push" ]] && NO_PUSH=true

# Resolve tag from git
if TAG="$(git describe --tags --exact-match 2>/dev/null)"; then
    RESOLVED="${TAG}"                                # vX.Y.Z (HEAD is the tag)
elif TAG="$(git describe --tags 2>/dev/null)"; then
    BASE="${TAG%%-*}"                                # vX.Y.Z portion
    SHORT="$(git rev-parse --short HEAD)"
    RESOLVED="${BASE}-sha${SHORT}"                   # vX.Y.Z-sha<short>
else
    SHORT="$(git rev-parse --short HEAD)"
    RESOLVED="sha-${SHORT}"                          # no tag in history
fi

echo "Building ${IMAGE_NAME}:${RESOLVED}"
docker build \
    --build-arg BUILD_VERSION="${RESOLVED}" \
    -t "${IMAGE_NAME}:${RESOLVED}" \
    -t "${IMAGE_NAME}:latest" \
    -f "${DOCKERFILE}" \
    "${CONTEXT}"

if ! $NO_PUSH; then
    docker push "${IMAGE_NAME}:${RESOLVED}"
    docker push "${IMAGE_NAME}:latest"
fi

echo "Resolved tag: ${RESOLVED}"
```

The skeleton above is illustrative — Nina adapts it to the project (paths, image name, additional build-args). The non-negotiables are: `set -euo pipefail`; the three-branch tag algorithm; pushing both the resolved tag and `:latest`; the `--no-push` flag; passing the resolved tag in as a build-arg so the image can embed it.

### `update.sh` — server-side pull and restart

Run on the production server. Order matters: **pull first**, so a registry failure does not take the app down before a working image is in place.

Structure:

```
#!/bin/bash
set -euo pipefail

IMAGE_NAME="<registry-host>/<namespace>/<image>"
CONTAINER_NAME="<container-name>"
ENV_FILE="/etc/<project>/env.production"             # gitignored, provisioned out-of-band
HOST_PORT="<host-port>"
CONTAINER_PORT="<container-port>"

echo "Pulling ${IMAGE_NAME}:latest"
sudo docker pull "${IMAGE_NAME}:latest"

echo "Stopping ${CONTAINER_NAME}"
sudo docker stop "${CONTAINER_NAME}" || true
sudo docker rm "${CONTAINER_NAME}" || true

echo "Starting ${CONTAINER_NAME}"
sudo docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    --env-file "${ENV_FILE}" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    "${IMAGE_NAME}:latest"

echo "Done. Container ${CONTAINER_NAME} running on host port ${HOST_PORT}."
```

The `sudo docker` prefix matches the common "docker not in the user's group" setup. Projects where the deploy user is in the docker group can drop the `sudo`. Either is fine; the recipe doesn't pick.

Removing the old image after pull (`docker image rm`) is **not** part of the locked flow — Docker garbage-collects unused images via `docker system prune`, and proactively deleting the previous image makes rollback (`docker run <previous-tag>`) impossible. Operators who need disk space schedule `docker system prune` on its own cadence.

### Pitfalls

- **Don't compute a version tag and then forget to use it.** The source this recipe was abstracted from did exactly that. Tag the image with the resolved version *and* push it; pushing only `:latest` makes "what's running in prod right now?" impossible to answer with `docker inspect`.
- **Don't derive the version from `git tag --sort=-v:refname | head -1`.** That returns the project's highest-ever version tag regardless of the current `HEAD` — every dev build gets mis-labelled with the latest release version. Use `git describe --tags --exact-match` / `git describe --tags` as shown above so the tag reflects the actual code being built.
- **Don't put secrets in `-e VAR=...`.** Inline env vars on the `docker run` command leak through `ps aux`, the user's shell history, and `docker inspect`'s container metadata. Use `--env-file` reading from a gitignored `.env.production`.
- **Don't pull *after* stopping the container.** A network hiccup at exactly the wrong moment leaves you with no running container and no image to start. Pull first, fail fast if the registry is unreachable, then stop and restart.
- **Don't omit `--restart unless-stopped`.** A reboot of the host otherwise drops the app on the floor.
- **Don't ship the Dockerfile without a non-root `USER`.** "We'll add it later" rarely happens.
- **Don't let `.env*` files into the build context.** Add them to `.dockerignore` from day one. A secret baked into an image layer survives even when the running container is restarted with a clean env file.
- **Don't call `docker login` from a script.** Credentials end up in shell history. Document the login command in the runbook and have operators run it once per machine.

## Test Guidance

This recipe produces operational scripts, not application code — there is no unit-test or UI suite to add. "Test Guidance" here is a **verification checklist** Ava walks through with Nina once implementation lands.

### Build verification

- `./buildpush.sh --no-push` completes successfully on a clean checkout.
- The resulting image runs locally (`docker run --rm -p <port>:<port> <image>:<tag>`) and the app responds on the expected port.
- The resolved tag is embedded in the image: `docker inspect <image>:<tag>` shows the label/env, *or* `docker run --rm <image>:<tag> cat /etc/build-info` returns the tag — whichever pattern the project picked.
- `docker image inspect` confirms the image runs as a non-root user.
- The image size is within a reasonable bound for the language (e.g. < 200MB for a Node app; < 50MB for a Go static binary). Bloat usually means the production stage carries dev dependencies.

### Tag-algorithm verification

Run `buildpush.sh --no-push` from three different git states and confirm the printed "Resolved tag" matches the rule:

- On a tagged commit (e.g. `git checkout v1.0.0`) → `v1.0.0`.
- On a descendant of a tag (one commit past `v1.0.0`) → `v1.0.0-sha<short>`.
- In a fresh repo with no tags (or a branch that diverged before any tag) → `sha-<short>`.

### Push verification

- `./buildpush.sh` (without `--no-push`) succeeds and the registry's UI / API shows both the resolved tag and `:latest`.
- The resolved tag and `:latest` point at the same image digest.

### Deploy verification (on the server)

- `./update.sh` succeeds when invoked manually.
- After the script returns, `docker ps` shows the container running with `--restart unless-stopped` (visible in `docker inspect`).
- `curl http://localhost:<host-port>/<health-or-root>` returns a healthy response.
- The container has the env vars it expects, sourced from `--env-file` (`docker exec <container> env | grep <known-var>`).
- Rebooting the host (or `sudo systemctl restart docker`) brings the container back automatically.

### Regression checks

- Running `./update.sh` twice in a row succeeds (idempotent — the second invocation finds the container running, stops it, removes it, starts the fresh one).
- Pushing a new build and re-running `./update.sh` swaps the container to the new image.
- A deliberately broken `.env.production` (missing required var) causes the container to fail fast with a clear log message — not silently start in a degraded state. (This depends on the application's startup validation; flag it as a follow-up if the app doesn't yet validate env at startup.)

## Variations

### Multi-arch builds (`buildx`)

Use `docker buildx build --platform linux/amd64,linux/arm64` instead of `docker build` to produce a manifest list covering both architectures. Required when the dev machine and the production host run different architectures (e.g. Apple Silicon dev, x86_64 server). Adds a `docker buildx create --use` bootstrap and a longer build time.

### CI-driven build and push

Move `buildpush.sh` into a CI pipeline (GitHub Actions, GitLab CI). The script's shape barely changes — what changes is where credentials live (CI secret store) and what triggers it (tag push, main-branch merge, manual dispatch). Likely candidate for a future `ci:docker-build-push` recipe; until then, the structure shown here transplants directly.

### Compose-based local dev

For a local-dev story that runs the app plus its dependencies (db, cache) with hot reload, a separate `docker-compose.yml` is the right tool — fundamentally different concern from production single-image deploy. Likely candidate for a future `dev:docker-compose` recipe.

### Blue/green / zero-downtime deploys

Replace the stop → rm → run cycle with: start the new container on a different name + port, switch a reverse proxy (nginx, Caddy, Traefik) to point at it, then stop the old one. Adds a proxy dependency and a healthcheck-gated cutover. Worth it when downtime cost exceeds the operational overhead.

### Image scanning, SBOM, signing

- Scanning: `trivy image <image>:<tag>` or registry-side scanning (GHCR, ECR, GAR all offer it). Run on every push.
- SBOM: `docker buildx build --sbom=true ...` emits a Software Bill of Materials alongside the image.
- Signing: `cosign sign <image>:<tag>` produces a verifiable signature; pair with `cosign verify` on the server.

Each is a low-cost addition; combined they're a meaningful security uplift. Pick up as the project's risk profile demands.

### Registry-specific `docker login` commands (record in `runbook.md`)

- **Docker Hub:** `echo "$DOCKERHUB_TOKEN" | docker login -u <user> --password-stdin`
- **GHCR:** `gh auth token | docker login ghcr.io -u <user> --password-stdin` (or a PAT with `write:packages`).
- **ECR:** `aws ecr get-login-password --region <region> | docker login --password-stdin <account>.dkr.ecr.<region>.amazonaws.com`
- **GAR:** `gcloud auth configure-docker <region>-docker.pkg.dev` (one-time per machine).
- **Generic self-hosted:** `docker login <registry-host>` then enter username + token.

The recipe does not call any of these from a script. The runbook records the right one for the project's chosen registry so operators know what to run once per machine.

### `sudo docker` vs. `docker` group

Two options; both are fine.

- **`sudo docker`** — every command needs `sudo`. Simpler permission model, more verbose scripts. The `update.sh` skeleton above uses this form.
- **`docker` group** — `usermod -aG docker <user>` once per server, then commands run without `sudo`. Convenience win, but membership in the docker group is effectively root (a container can mount the host filesystem). Restrict the group to trusted users.

Whichever the project picks, record it in `runbook.md` so the operational commands are consistent.
