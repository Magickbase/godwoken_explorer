FROM bitwalker/alpine-elixir-phoenix:1.13.1 as builder

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3 file qemu-x86_64

ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc
ENV GLIBC_VERSION=2.30-r0

RUN set -ex && \
  apk --update add libstdc++ curl ca-certificates && \
  for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION}; \
  do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
  apk add --allow-untrusted /tmp/*.apk && \
  rm -v /tmp/*.apk && \
  /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

# Get Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="$HOME/.cargo/bin:${PATH}"
ENV RUSTFLAGS="-C target-feature=-crt-static"

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

ARG GODWOKEN_CHAIN
ARG GWSCAN_GRAPHIQL
ARG GRAFANA_HOST
ARG GRAFANA_AUTH_TOKEN
ARG GRAFANA_FOLDER_NAME

ENV GODWOKEN_CHAIN=$GODWOKEN_CHAIN
ENV GWSCAN_GRAPHIQL=$GWSCAN_GRAPHIQL
ENV GRAFANA_HOST=$GRAFANA_HOST
ENV GRAFANA_AUTH_TOKEN=$GRAFANA_AUTH_TOKEN
ENV GRAFANA_FOLDER_NAME=$GRAFANA_FOLDER_NAME

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

FROM bitwalker/alpine-elixir-phoenix:1.13.1 as deploy

WORKDIR "/app"
ENV MIX_ENV="prod"

# contract compile needs solc
RUN npm install --save solc

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/godwoken_explorer ./

CMD ["/app/bin/server"]
