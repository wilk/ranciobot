FROM elixir:1.6.5-alpine

RUN apk add --no-cache bash

# force install hex locally (used to install deps)
RUN mix local.hex --force

WORKDIR /opt/app
COPY . .

# install deps
RUN mix deps.get
RUN mix local.rebar --force
#RUN mix release

CMD ["mix", "run"]
