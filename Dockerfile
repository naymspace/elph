# Extend from the official Elixir image
FROM elixir:1.9-alpine

RUN apk --no-cache add mariadb-client bash inotify-tools build-base

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY mix.* /app/
WORKDIR /app

# set it here, so we won't have to recompile everything later
ENV MIX_ENV test

# Install dependencies
RUN mix local.hex --force && \
  mix local.rebar --force && \
  mix do deps.get && mix do deps.compile

COPY . /app

# Compile the project
RUN mix do compile
