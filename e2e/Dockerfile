# pulse-api's e2e tests as an image, built and pushed next to the app image
# with the same sha-<short> tag (.github/workflows/pipeline.yml). gitops-poc's
# Kargo path runs the one from the same commit as the app it's verifying,
# with its e2e-playwright verification template.
#
# Contract: takes the base URL as its only argument, exits 0 when every
# test passes.
#
#   docker build -t pulse-api-e2e e2e
#   docker run --rm --network gitops-poc_k8s-management pulse-api-e2e http://k3s-stg:30081
#
# The base image's Playwright version must match package.json exactly - it
# ships the browsers that version expects.
FROM mcr.microsoft.com/playwright:v1.65.0-noble

WORKDIR /e2e
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .

USER pwuser
ENTRYPOINT ["/e2e/run.sh"]
