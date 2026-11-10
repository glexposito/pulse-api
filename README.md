# pulse-api

`pulse-api` is a small proof of concept for health signals using Axum.

It currently exposes:

- `GET /`
- `GET /hello`
- `GET /live`
- `GET /ready`

The goal is to keep this service minimal and use it as a base for adding OpenTelemetry instrumentation next.

## Pipeline

`.github/workflows/pipeline.yml` builds the image once on GitHub's cloud,
pushes it to GHCR, then promotes that exact digest
**internal → stg → prod** (`.github/workflows/deploy.yml`, once per stage):

1. Pin the digest in [gitops-poc](https://github.com/glexposito/gitops-poc)'s
   `apps/pulse-api/overlays/<stage>` and push.
2. `argocd app sync pulse-api-<stage>` to that commit, wait until Healthy.
3. `scripts/e2e.sh http://k3s-<stage>:30080`. A failure stops the promotion.

Deploy stages run on a self-hosted runner (`runs-on: [self-hosted, local-k8s]`):
the `github-runner` service in gitops-poc's `cluster/docker-compose.yaml`, because
Argo CD and the clusters only exist on that machine. The runner only connects
out to GitHub, so nothing has to be exposed.

Setup (deploy key, runner, protecting this public repo) and troubleshooting:
[gitops-poc/docs/ci-setup.md](https://github.com/glexposito/gitops-poc/blob/main/docs/ci-setup.md).

The build also pushes `ghcr.io/glexposito/pulse-api-e2e`, the Playwright
tests in `e2e/` as an image, with the same `sha-*` tag. gitops-poc's Kargo
path promotes the same builds a second way and uses that image to verify each
stage: see
[gitops-poc/docs/kargo.md](https://github.com/glexposito/gitops-poc/blob/main/docs/kargo.md).

Run the Playwright tests yourself against any deployed copy:

```bash
cd e2e && npm ci && npx playwright install chromium
BASE_URL=http://localhost:8091 npx playwright test   # internal, Kargo copy
```

As with `scripts/e2e.sh`, the `/hostname` test expects a pod name, so it
fails against a local `cargo run`.

## Pipeline test

Test commit to build a new image and promote it internal → stg → prod.

- Local time: 2026-11-07 15:24:53 NZDT (+1300)
- Commit time: 2026-11-07 15:24:53 NZDT (+1300)
