#!/usr/bin/env bash
# exit on error
set -o errexit

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Compile assets
MIX_ENV=prod mix assets.setup
MIX_ENV=prod mix assets.build
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix phx.gen.release 

# Build the release and overwrite the existing release directory
MIX_ENV=prod mix release --overwrite