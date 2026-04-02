FROM rust:1.94-slim AS builder

WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends pkg-config ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY Cargo.toml Cargo.lock ./
COPY src ./src

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN cargo build --locked --release

FROM gcr.io/distroless/cc-debian12:nonroot AS runtime-distroless

WORKDIR /app

COPY --from=builder /app/target/release/pulse-api /app/pulse-api

EXPOSE 8080

ENV PORT=8080

CMD ["/app/pulse-api"]
