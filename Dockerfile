FROM rust:1.94-alpine3.23 AS builder

WORKDIR /app

RUN apk add --no-cache musl-dev

COPY Cargo.toml Cargo.lock ./
COPY src ./src

ENV CARGO_NET_GIT_FETCH_WITH_CLI=true
ENV RUSTFLAGS="-C target-feature=+crt-static"

RUN cargo build --locked --release

FROM alpine:3.22 AS runtime-alpine

WORKDIR /app

COPY --from=builder /app/target/release/pulse-api /app/pulse-api

EXPOSE 8080

ENV PORT=8080

USER 65532:65532

CMD ["/app/pulse-api"]

FROM gcr.io/distroless/static-debian12:nonroot AS runtime-distroless

WORKDIR /app

COPY --from=builder /app/target/release/pulse-api /app/pulse-api

EXPOSE 8080

ENV PORT=8080

CMD ["/app/pulse-api"]
