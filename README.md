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

1. Pin the digest in [k8s-keda-poc](https://github.com/glexposito/k8s-keda-poc)'s
   `apps/pulse-api/overlays/<stage>` and push.
2. Argo CD (auto-sync) deploys it; wait until that commit is Synced + Healthy.
3. `scripts/e2e.sh http://k3s-<stage>:30080`. A failure stops the promotion.

Deploy stages run on a self-hosted runner (`runs-on: [self-hosted, local-k8s]`):
the `github-runner` service in k8s-keda-poc's `docker-compose.yaml`, because
Argo CD and the clusters only exist on that machine. The runner only connects
out to GitHub, so nothing has to be exposed.

Setup (deploy key, runner, protecting this public repo) and troubleshooting:
[k8s-keda-poc/docs/ci-setup.md](https://github.com/glexposito/k8s-keda-poc/blob/main/docs/ci-setup.md).

## Pipeline test

Test commit to build a new image and promote it internal → stg → prod.

- Local time: 2026-11-07 14:24:27 NZDT (+1300)
- Commit time: 2026-11-07 14:24:27 NZDT (+1300)
