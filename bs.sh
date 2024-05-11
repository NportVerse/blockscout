#!/bin/bash

export ETHEREUM_JSONRPC_VARIANT=geth
export COIN=POA
export NETWORK=POA

# postgresql의 port, db, 계정 config
export DATABASE_URL=postgresql://lsj:11@localhost:5432/blockscout

# geth node의 rpc url 주소
export ETHEREUM_JSONRPC_HTTP_URL=http://localhost:8545

# db 초기화
PGPASSWORD=11 dropdb -U lsj blockscout
PGPASSWORD=11 createdb -U lsj blockscout

mix do deps.get, local.rebar --force, deps.compile, compile
mix ecto.migrate

mix phx.server

# cd _build/dev/lib/block_scout_web/priv/cert