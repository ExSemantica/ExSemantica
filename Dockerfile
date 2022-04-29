# Copyright 2019-2022 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Mostly based off this:
# https://blog.miguelcoba.com/deploying-a-phoenix-16-app-with-docker-and-elixir-releases
#
# ==============================================================================
# Build the application
# ==============================================================================
ARG VER_ELIXIR
ARG VER_ERLANG
ARG MIX_ENV="prod"

# Time to build
FROM hexpm/elixir:${VER_ELIXIR}-erlang-${VER_ERLANG}-alpine-3.15.3 AS build

RUN apk add --no-cache build-base git python3 curl

# Serve here
WORKDIR /srv/app

RUN mix local.hex --force && \
    mix local.rebar --force

ARG MIX_ENV
ENV MIX_ENV="${MIX_ENV}"

COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# First copy config
RUN mkdir config
COPY config/config.exs config/$MIX_ENV.exs config/

# Get dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy what we need
COPY priv priv
COPY assets assets
COPY lib lib

# Compile project
RUN mix assets.deploy && \
    mix compile

# Copy runtime configuration file
COPY config/runtime.exs config/

# Assemble release
RUN mix release

# ==============================================================================
# Run the application
# ==============================================================================
FROM alpine:3.15.3 as app

ARG MIX_ENV

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

# Declare our user
ENV USER="elixir"

# Change directory to user
WORKDIR "/home/#{USER}/app"

# Unprivileged user for release
RUN \
    addgroup \
    -g 1000 \
    -S "${USER}" \
    && adduser \
    -s /bin/sh \
    -u 1000 \
    -G "${USER}" \
    -h "/home/${USER}" \
    -D "${USER}" \
    && su "${USER}"

# De-escalate privilege to user
USER "${USER}"

# Copy from /srv/app
COPY --from=build --chown="${USER}":"${USER}" /srv/app/_build/"${MIX_ENV}"/rel/exsemantica ./


ENTRYPOINT [ "bin/exsemantica" ]
CMD [ "start" ]
