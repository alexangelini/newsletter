FROM lukemathwalker/cargo-chef as planner
WORKDIR /app
COPY . .
RUN cargo chef prepare  --recipe-path recipe.json

FROM lukemathwalker/cargo-chef as cacher
WORKDIR /app
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json

FROM rust:1.49 AS builder
WORKDIR /app
COPY --from=cacher /app/target target
COPY --from=cacher /usr/local/cargo /usrc/local/cargo
COPY . .
ENV SQLX_OFFLINE true
RUN cargo build --release --bin newsletter


FROM debian:buster-slim AS runtime
WORKDIR /app
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends openssl \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/newsletter newsletter
COPY configuration configuration
ENV APP_ENVIRONMENT production
ENTRYPOINT ["./newsletter"]