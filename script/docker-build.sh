#!/bin/bash -eu

cd /workspace
CRFLAGS="--static" make build-release
