# Extend from the official Elixir image
FROM hexpm/elixir:1.13.4-erlang-24.3.4.2-alpine-3.16.0

RUN apk --no-cache add mariadb-client bash inotify-tools build-base git

# prepare workdir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set it here, so we won't have to recompile everything later
ENV MIX_ENV test

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get

# copy config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/ .*
RUN mix deps.compile

COPY . ./

# Compile the project
RUN mix compile
