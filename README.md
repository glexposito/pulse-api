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
2. `argocd app sync pulse-api-<stage>` to that commit, wait until Healthy.
3. `scripts/e2e.sh http://k3s-<stage>:30080`. A failure stops the promotion.

Deploy stages run on a self-hosted runner (`runs-on: [self-hosted, local-k8s]`):
the `github-runner` service in k8s-keda-poc's `docker-compose.yaml`, because
Argo CD and the clusters only exist on that machine. The runner only connects
out to GitHub, so nothing has to be exposed.

Setup:

- Repo secret `GITOPS_SSH_KEY`: the private half of a **write** deploy key on
  `glexposito/k8s-keda-poc` (the built-in `GITHUB_TOKEN` can't push to another
  repo). Create both halves with:

  ```bash
  ssh-keygen -t ed25519 -N "" -f /tmp/gitops_key -C "pulse-api pipeline"
  gh repo deploy-key add /tmp/gitops_key.pub -R glexposito/k8s-keda-poc --allow-write -t "pulse-api pipeline"
  gh secret set GITOPS_SSH_KEY -R glexposito/pulse-api < /tmp/gitops_key
  rm /tmp/gitops_key /tmp/gitops_key.pub
  ```
- The runner, started from k8s-keda-poc (see its README).

## Pipeline test

Test commit to build a new image and promote it internal → stg → prod.

- Local time: 2026-11-07 14:03:23 NZDT (+1300)
- Commit time: 2026-11-07 14:03:23 NZDT (+1300)
