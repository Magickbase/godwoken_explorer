ARG ELIXIR_VERSION=1.13.4
ARG OTP_VERSION=25.3.2.20
ARG ALPINE_VERSION=3.18.9
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}"

FROM ${BUILDER_IMAGE} as builder

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 file qemu-x86_64 rust cargo \
    ncurses-libs \
    libstdc++ \
    libgcc \
    musl \
    gcompat \
    gcc \
    g++ \
    libc6-compat

# Get Rust
RUN echo $PATH && which cargo

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

ARG GODWOKEN_CHAIN
ARG GWSCAN_GRAPHIQL

ENV GODWOKEN_CHAIN=$GODWOKEN_CHAIN
ENV GWSCAN_GRAPHIQL=$GWSCAN_GRAPHIQL

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
RUN mkdir config/prod

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
COPY config/chains/ config/chains/
COPY native native
RUN mix deps.compile

COPY priv priv

# note: if your project uses a tool like https://purgecss.com/,
# which customizes asset compilation based on what it finds in
# your Elixir templates, you will need to move the asset compilation
# step down so that `lib` is available.
COPY assets assets

# compile assets
RUN mix assets.deploy

# Compile the release
COPY lib lib
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

FROM ${RUNNER_IMAGE} as deploy

WORKDIR "/app"
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/godwoken_explorer ./

CMD ["/app/bin/server"]
