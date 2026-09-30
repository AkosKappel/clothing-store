# Build: compile a release. Run: a slim Debian with only the release.
ARG ELIXIR_VERSION=1.20.4
ARG OTP_VERSION=29.1.1
ARG DEBIAN_VERSION=trixie-20260918-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# git: heroicons comes straight from GitHub
RUN apt-get update && apt-get install -y --no-install-recommends build-essential git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mix local.hex --force && mix local.rebar --force
ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

RUN mix assets.setup
COPY priv priv
COPY lib lib
COPY assets assets
RUN mix assets.deploy
RUN mix compile

COPY config/runtime.exs config/
COPY rel rel
RUN mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 libsctp1 locales ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 MIX_ENV=prod

WORKDIR /app
RUN chown nobody /app
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/clothing_store ./
USER nobody

EXPOSE 4000
CMD ["/app/bin/server"]
